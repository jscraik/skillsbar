import Foundation
@testable import SkillsBarCore
import XCTest

final class ShellTests: XCTestCase {
    func testRunPrefersStableToolLocationsOverVersionManagerShims() throws {
        guard Shell.run("command -v python3", cwd: URL(fileURLWithPath: "/private/tmp"), timeout: 10).exitCode == 0 else {
            throw XCTSkip("python3 is not installed on this host.")
        }
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

    func testRunCreatesIsolatedToolDirectories() {
        let command = "test -d \"$ZDOTDIR\" -a -d \"$XDG_CACHE_HOME\" -a -d \"$MISE_CACHE_DIR\" -a -d \"$UV_CACHE_DIR\""

        let result = Shell.run(command, cwd: URL(fileURLWithPath: "/private/tmp"), timeout: 10)

        XCTAssertEqual(result.exitCode, 0)
    }

    func testSanitizedPathRemovesMiseEntriesAndKeepsRequiredTools() {
        let result = Shell.sanitizedPath(
            "/Users/jamie/.local/share/mise/shims:/Users/jamie/.local/bin:/usr/bin:/Users/jamie/.local/share/mise/bin",
            localBin: "/Users/jamie/.local/bin"
        )

        XCTAssertFalse(result.split(separator: ":").contains { $0.split(separator: "/").contains("mise") })
        XCTAssertTrue(result.split(separator: ":").contains("/Users/jamie/.local/bin"))
        XCTAssertTrue(result.split(separator: ":").contains("/usr/bin"))
        XCTAssertTrue(result.split(separator: ":").contains("/opt/homebrew/bin"))
        XCTAssertEqual(result.split(separator: ":").count, Set(result.split(separator: ":")).count)
    }

    func testRunDisablesMiseConfigForSdkChildren() {
        let result = Shell.run(
            "printf '%s\\n' \"$MISE_NO_CONFIG\" \"$MISE_NO_ENV\" \"$MISE_NO_HOOKS\" \"$MISE_CONFIG_FILE\"",
            cwd: URL(fileURLWithPath: "/private/tmp"),
            timeout: 5
        )

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.stdout, "1\n1\n1\n/dev/null\n")
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
