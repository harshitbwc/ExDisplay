import React from "react";
import { AbsoluteFill, interpolate, spring, useCurrentFrame, useVideoConfig } from "remotion";
import { C, font, gradient } from "../theme";
import { Rise } from "../Rise";

const steps = [
  { title: "Plug in your tablet", text: "Turn on USB debugging once." },
  { title: "Install the two apps", text: "One for your Mac, one for your tablet." },
  { title: "Open and go", text: "ExDisplay connects on its own." },
];

const Step: React.FC<{ index: number; title: string; text: string }> = ({ index, title, text }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - (20 + index * 18), fps, config: { damping: 200 } });
  return (
    <div
      style={{
        flex: 1,
        display: "flex",
        flexDirection: "column",
        gap: 20,
        opacity: s,
        translate: `${interpolate(s, [0, 1], [-50, 0])}px 0px`,
      }}
    >
      <div
        style={{
          width: 120,
          height: 120,
          borderRadius: 36,
          background: gradient,
          display: "grid",
          placeItems: "center",
          color: "#fff",
          fontSize: 72,
          fontWeight: 800,
        }}
      >
        {index + 1}
      </div>
      <div style={{ fontSize: 60, fontWeight: 800, color: C.text, lineHeight: 1.1, letterSpacing: -1.2 }}>{title}</div>
      <div style={{ fontSize: 40, fontWeight: 500, color: C.muted, lineHeight: 1.3 }}>{text}</div>
    </div>
  );
};

export const Steps: React.FC = () => (
  <AbsoluteFill style={{ fontFamily: font, padding: "0 120px", justifyContent: "center", gap: 90 }}>
    <Rise>
      <div style={{ fontSize: 112, fontWeight: 800, letterSpacing: -3, color: C.text }}>Set up in three steps.</div>
    </Rise>
    <div style={{ display: "flex", gap: 70 }}>
      {steps.map((s, i) => (
        <Step key={s.title} index={i} {...s} />
      ))}
    </div>
  </AbsoluteFill>
);
