import React from "react";
import { AbsoluteFill } from "remotion";
import { Lockup, LogoMark } from "./Logo";

// 1024x1024 transparent PNG of the mark.
export const LogoMarkStill: React.FC = () => (
  <AbsoluteFill style={{ alignItems: "center", justifyContent: "center" }}>
    <LogoMark size={1024} id="still-mark" />
  </AbsoluteFill>
);

// Mark + wordmark for light backgrounds is not provided: the wordmark is light-on-dark.
export const LogoLockupStill: React.FC = () => (
  <AbsoluteFill
    style={{
      alignItems: "center",
      justifyContent: "center",
      background: "#0A0F1E",
    }}
  >
    <Lockup markSize={260} id="still-lockup" />
  </AbsoluteFill>
);
