import type { Metadata, Viewport } from "next";
import "./globals.css";

const title = "Know what your skill needs next · SkillsBar";
const description = "Inspect nine evidence gates, see what needs attention, and copy the next command from your macOS menu bar.";

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  colorScheme: "dark",
  themeColor: "#101216",
};

/** Build page and social-preview metadata using the walkthrough's local image assets. */
export function generateMetadata(): Metadata {
  const socialImage = "/og.png";
  return {
    title,
    description,
    icons: {
      icon: "/skillsbar-icon-168.png",
      shortcut: "/skillsbar-icon-168.png",
    },
    openGraph: {
      type: "website",
      title,
      description,
      images: [{ url: socialImage, width: 1729, height: 910, alt: "SkillsBar candidate-bound evidence walkthrough" }],
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images: [socialImage],
    },
  };
}

/** Wrap the walkthrough in an English document using the shared global styles. */
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
