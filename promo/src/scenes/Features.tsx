import React from "react";
import { AbsoluteFill, spring, useCurrentFrame, useVideoConfig, interpolate } from "remotion";
import { C, font, gradient } from "../theme";
import { Rise } from "../Rise";

const Icon: React.FC<{ kind: "cable" | "lock" | "code" }> = ({ kind }) => (
  <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round">
    {kind === "cable" && (
      <>
        <path d="M9 3v5M15 3v5" />
        <path d="M6 8h12v3a6 6 0 0 1-12 0V8z" />
        <path d="M12 17v4" />
      </>
    )}
    {kind === "lock" && (
      <>
        <rect x="5" y="11" width="14" height="10" rx="2.5" />
        <path d="M8 11V8a4 4 0 0 1 8 0v3" />
      </>
    )}
    {kind === "code" && (
      <>
        <path d="M8 7l-5 5 5 5" />
        <path d="M16 7l5 5-5 5" />
        <path d="M13.5 5l-3 14" />
      </>
    )}
  </svg>
);

const cards: { icon: "cable" | "lock" | "code"; title: string; text: string }[] = [
  { icon: "cable", title: "Wired", text: "Steady over a USB cable. No Wi-Fi needed." },
  { icon: "lock", title: "Private", text: "Stays on your computer. No accounts, no tracking." },
  { icon: "code", title: "Open source", text: "Free to use, under the MIT license." },
];

const Card: React.FC<{ index: number; icon: "cable" | "lock" | "code"; title: string; text: string }> = ({ index, icon, title, text }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - (22 + index * 10), fps, config: { damping: 200 } });
  return (
    <div
      style={{
        flex: 1,
        padding: 44,
        borderRadius: 36,
        background: "rgba(22,32,61,0.85)",
        border: `2px solid ${C.line}`,
        opacity: s,
        translate: `0px ${interpolate(s, [0, 1], [60, 0])}px`,
      }}
    >
      <div
        style={{
          width: 112,
          height: 112,
          borderRadius: 32,
          background: gradient,
          display: "grid",
          placeItems: "center",
          marginBottom: 36,
        }}
      >
        <Icon kind={icon} />
      </div>
      <div style={{ fontSize: 68, fontWeight: 800, color: C.text, letterSpacing: -1.5 }}>{title}</div>
      <div style={{ fontSize: 40, fontWeight: 500, color: C.muted, lineHeight: 1.3, marginTop: 14 }}>{text}</div>
    </div>
  );
};

export const Features: React.FC = () => (
  <AbsoluteFill style={{ fontFamily: font, padding: "0 120px", justifyContent: "center", gap: 64 }}>
    <Rise>
      <div style={{ fontSize: 112, fontWeight: 800, letterSpacing: -3, color: C.text }}>Simple, private, free.</div>
    </Rise>
    <div style={{ display: "flex", gap: 36 }}>
      {cards.map((c, i) => (
        <Card key={c.title} index={i} {...c} />
      ))}
    </div>
  </AbsoluteFill>
);
