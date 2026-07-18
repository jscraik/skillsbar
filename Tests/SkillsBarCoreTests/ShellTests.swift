import Foundation
import SkillsBarCore
import XCTest

final class ShellTests: XCTestCase {
    func testRunPrefersStableToolLocationsOverVersionManagerShims() {
        let result = Shell.run("command -v python3", cwd: URL(fileURLWithPath: "/private/tmp"), timeout: 10)

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertFalse(result.stdout.contains("/mise/shims/"))
    }

    func testRunProvidesTheManagedValidationPythonWhenAvailable() throws {
        let expected = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".venvs/pyyaml/bin/python")
        guard FileManager.default.isExecutableFile(atPath: expected.path) else {
            throw XCTSkip("Managed PyYAML Python is not installed on this host.")
        }

        let result = Shell.run("printf '%s' \"$PYTHON_BIN\"", cwd: URL(fileURLWithPath: "/private/tmp"), timeout: 10)

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.stdout, expected.path)
    }

    func testRunConstrainsPackageManagerNetworkAndConcurrency() {
        let command = "printf '%s|%s|%s|%s' \"$MISE_OFFLINE\" \"$MISE_JOBS\" \"$UV_OFFLINE\" \"$npm_config_offline\""

        let result = Shell.run(command, cwd: URL(fileURLWithPath: "/private/tmp"), timeout: 10)

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.stdout, "1|2|1|true")
    }

    func testRunCapturesLargeStdoutAndStderrWithoutDeadlock() {
        let byteCount = 3_000_000
        let command = """
        python3 - <<'PY'
        import sys
        count = \(byteCount)
        sys.stdout.write("x" * count)
        sys.stdout.flush()
        sys.stderr.write("y" * count)
        sys.stderr.flush()
        PY
        """

        let result = Shell.run(command, cwd: URL(fileURLWithPath: "/private/tmp"), timeout: 10)

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.stdout.utf8.count, byteCount)
        XCTAssertEqual(result.stderr.utf8.count, byteCount)
        XCTAssertTrue(result.stdout.allSatisfy { $0 == "x" })
        XCTAssertTrue(result.stderr.allSatisfy { $0 == "y" })
    }
}
