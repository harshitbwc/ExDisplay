import { loadFont } from "@remotion/google-fonts/Inter";

const { fontFamily } = loadFont("normal", {
  weights: ["500", "600", "700", "800"],
  subsets: ["latin"],
});

export const font = fontFamily;

export const C = {
  bg: "#0A0F1E",
  bg2: "#111A36",
  surface: "#16203D",
  line: "#2A3868",
  text: "#F1F5F9",
  muted: "#9AA8C4",
  blue: "#3B82F6",
  violet: "#8B5CF6",
  mint: "#34D399",
  amber: "#FBBF24",
  rose: "#FB7185",
};

export const gradient = `linear-gradient(135deg, ${C.blue}, ${C.violet})`;

export const wallpaper =
  "linear-gradient(135deg, #1B2A5E 0%, #3A2A78 55%, #1A3C6E 100%)";

// Text that is filled with the brand gradient.
export const gradientText: React.CSSProperties = {
  background: gradient,
  WebkitBackgroundClip: "text",
  backgroundClip: "text",
  color: "transparent",
};
