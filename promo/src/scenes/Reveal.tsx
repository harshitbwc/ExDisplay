import React from "react";
import {
  AbsoluteFill,
  Easing,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { C, font } from "../theme";
import { LogoMark, Wordmark } from "../Logo";
import { Rise } from "../Rise";

export const Reveal: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const pop = spring({ frame, fps, config: { damping: 14, stiffness: 120 } });
  return (
    <AbsoluteFill
      style={{ fontFamily: font, alignItems: "center", justifyContent: "center" }}
    >
      <div
        style={{
          position: "absolute",
          width: 900,
          height: 900,
          borderRadius: "50%",
          background:
            "radial-gradient(circle, rgba(99,102,241,0.38), rgba(99,102,241,0) 65%)",
          opacity: interpolate(frame, [0, 30], [0, 1], {
            extrapolateRight: "clamp",
          }),
        }}
      />
      <div
        style={{
          scale: interpolate(pop, [0, 1], [0.5, 1]),
          rotate: interpolate(frame, [0, 30], ["-10deg", "0deg"], {
            extrapolateRight: "clamp",
            easing: Easing.bezier(0.16, 1, 0.3, 1),
          }),
          opacity: interpolate(frame, [0, 10], [0, 1], {
            extrapolateRight: "clamp",
          }),
        }}
      >
        <LogoMark size={260} id="reveal" />
      </div>
      <Rise delay={14} style={{ marginTop: 44 }}>
        <Wordmark size={150} />
      </Rise>
      <Rise delay={30} style={{ marginTop: 28 }}>
        <div
          style={{
            fontSize: 60,
            fontWeight: 500,
            color: C.muted,
            textAlign: "center",
            lineHeight: 1.25,
          }}
        >
          Your Android tablet, as your Mac’s second display.
        </div>
      </Rise>
    </AbsoluteFill>
  );
};
