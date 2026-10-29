import React from "react";
import { AbsoluteFill, Easing, interpolate, useCurrentFrame } from "remotion";
import { C, font, gradientText } from "../theme";
import { Rise } from "../Rise";

export const Hook: React.FC = () => {
  const frame = useCurrentFrame();
  // The first line steps back once the second line arrives.
  const dim = interpolate(frame, [40, 60], [1, 0.3], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(0.16, 1, 0.3, 1),
  });
  return (
    <AbsoluteFill
      style={{
        fontFamily: font,
        justifyContent: "center",
        padding: "0 160px",
        gap: 24,
      }}
    >
      <Rise delay={4}>
        <div
          style={{
            fontSize: 132,
            fontWeight: 800,
            letterSpacing: -4,
            lineHeight: 1.05,
            color: C.text,
            opacity: dim,
          }}
        >
          Short on screen space?
        </div>
      </Rise>
      <Rise delay={44}>
        <div
          style={{
            fontSize: 132,
            fontWeight: 800,
            letterSpacing: -4,
            lineHeight: 1.05,
            color: C.text,
          }}
        >
          You already own
          <br />a <span style={gradientText}>second screen.</span>
        </div>
      </Rise>
    </AbsoluteFill>
  );
};
