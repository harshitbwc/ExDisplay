import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { C, font, gradient, gradientText } from "../theme";
import { Lockup } from "../Logo";
import { Rise } from "../Rise";

const Pill: React.FC<{ children: string; solid?: boolean }> = ({ children, solid }) => (
  <div
    style={{
      padding: "26px 52px",
      borderRadius: 999,
      fontSize: 44,
      fontWeight: 700,
      color: "#fff",
      background: solid ? gradient : "rgba(255,255,255,0.08)",
      border: solid ? "none" : `2px solid ${C.line}`,
    }}
  >
    {children}
  </div>
);

export const Cta: React.FC = () => {
  const frame = useCurrentFrame();
  const glow = interpolate(frame, [0, 40], [0, 1], { extrapolateRight: "clamp" });
  return (
    <AbsoluteFill style={{ fontFamily: font, alignItems: "center", justifyContent: "center" }}>
      <div
        style={{
          position: "absolute",
          width: 1100,
          height: 1100,
          borderRadius: "50%",
          background: "radial-gradient(circle, rgba(99,102,241,0.3), rgba(99,102,241,0) 62%)",
          opacity: glow,
        }}
      />
      <Rise>
        <Lockup markSize={190} id="cta" />
      </Rise>
      <Rise delay={14} style={{ marginTop: 34 }}>
        <div style={{ fontSize: 64, fontWeight: 600, color: C.muted }}>Free &amp; open source</div>
      </Rise>
      <Rise delay={26} style={{ marginTop: 56, display: "flex", gap: 28 }}>
        <Pill solid>Download for Mac</Pill>
        <Pill>Download for Android</Pill>
      </Rise>
      <Rise delay={40} style={{ marginTop: 56 }}>
        <div style={{ fontSize: 60, fontWeight: 700, ...gradientText }}>harshitbwc.github.io/ExDisplay</div>
      </Rise>
      <Rise delay={50} style={{ marginTop: 20 }}>
        <div style={{ fontSize: 36, fontWeight: 500, color: C.muted }}>Apple Silicon Mac · macOS 14+ · Android 8+</div>
      </Rise>
    </AbsoluteFill>
  );
};
