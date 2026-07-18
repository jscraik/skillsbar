import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

const title = "When evidence goes stale · SkillsBar";
const description = "See one changed Skill stop at stale proof before a maintainer decides to ship.";

export function generateMetadata(): Metadata {
  const socialImage = "/og.png";
  return {
    title,
    description,
    icons: {
      icon: "/skillsbar-icon.png",
      shortcut: "/skillsbar-icon.png",
    },
    openGraph: {
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

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body className={`${geistSans.variable} ${geistMono.variable}`}>{children}</body>
    </html>
  );
}
