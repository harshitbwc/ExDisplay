import React from "react";
import { C, font, gradientText } from "./theme";

// The ExDisplay mark: a display plus a smaller tablet beside it, on a gradient tile.
// Keep in sync with docs/assets/logo.svg.
export const LogoMark: React.FC<{ size: number; id?: string }> = ({
  size,
  id = "exd-grad",
}) => (
  <svg width={size} height={size} viewBox="0 0 256 256" fill="none">
    <defs>
      <linearGradient
        id={id}
        x1="0"
        y1="0"
        x2="256"
        y2="256"
        gradientUnits="userSpaceOnUse"
      >
        <stop offset="0" stopColor="#3B82F6" />
        <stop offset="1" stopColor="#7C3AED" />
      </linearGradient>
    </defs>
    <rect width="256" height="256" rx="58" fill={`url(#${id})`} />
    <rect
      x="30"
      y="66"
      width="122"
      height="84"
      rx="14"
      stroke="#fff"
      strokeWidth="12"
    />
    <path
      d="M91 150V176M62 180H120"
      stroke="#fff"
      strokeWidth="12"
      strokeLinecap="round"
    />
    <rect x="166" y="96" width="60" height="92" rx="12" fill="#fff" />
    <circle cx="196" cy="174" r="5" fill="#5B5BEF" />
  </svg>
);

export const Wordmark: React.FC<{ size: number; color?: string }> = ({
  size,
  color = C.text,
}) => (
  <span
    style={{
      fontFamily: font,
      fontWeight: 800,
      fontSize: size,
      letterSpacing: -size * 0.03,
      lineHeight: 1,
      color,
    }}
  >
    <span style={gradientText}>Ex</span>Display
  </span>
);

export const Lockup: React.FC<{ markSize: number; id?: string }> = ({
  markSize,
  id,
}) => (
  <div style={{ display: "flex", alignItems: "center", gap: markSize * 0.28 }}>
    <LogoMark size={markSize} id={id} />
    <Wordmark size={markSize * 0.78} />
  </div>
);
