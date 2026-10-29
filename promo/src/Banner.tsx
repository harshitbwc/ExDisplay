import React from "react";
import { AbsoluteFill } from "remotion";
import { C, font, gradient } from "./theme";
import { Lockup } from "./Logo";
import {
  MacDisplay,
  Tablet,
  WindowMock,
} from "./Devices";

const Pill: React.FC<{ children: string }> = ({ children }) => (
  <div
    style={{
      padding: "10px 22px",
      borderRadius: 999,
      fontSize: 22,
      fontWeight: 700,
      color: C.text,
      background: "rgba(255,255,255,0.08)",
      border: `1.5px solid ${C.line}`,
    }}
  >
    {children}
  </div>
);

// 1280x640 — used as the GitHub social preview, the Open Graph image and the README banner.
export const Banner: React.FC = () => (
  <AbsoluteFill
    style={{
      fontFamily: font,
      background: `radial-gradient(900px 600px at 15% 0%, ${C.bg2}, ${C.bg} 70%)`,
      overflow: "hidden",
    }}
  >
    <AbsoluteFill
      style={{
        backgroundImage:
          "radial-gradient(rgba(148,163,184,0.14) 1.2px, transparent 1.2px)",
        backgroundSize: "40px 40px",
      }}
    />
    <div
      style={{
        position: "absolute",
        right: -120,
        top: 60,
        width: 820,
        height: 820,
        borderRadius: "50%",
        background:
          "radial-gradient(circle, rgba(99,102,241,0.32), rgba(99,102,241,0) 65%)",
      }}
    />

    <div style={{ position: "absolute", left: 72, top: 96 }}>
      <Lockup markSize={92} id="banner" />
    </div>
    <div
      style={{
        position: "absolute",
        left: 72,
        top: 250,
        width: 520,
        fontSize: 44,
        fontWeight: 700,
        lineHeight: 1.2,
        letterSpacing: -1,
        color: C.text,
      }}
    >
      Turn your Android tablet into a second display for your Mac.
    </div>
    <div style={{ position: "absolute", left: 72, top: 470, display: "flex", gap: 14 }}>
      <Pill>Wired</Pill>
      <Pill>Touch</Pill>
      <Pill>Free &amp; open source</Pill>
    </div>

    <div style={{ position: "absolute", left: 640, top: 118 }}>
      <MacDisplay width={480} height={300}>
        <WindowMock w={190} h={140} title="Notes" kind="doc" accent={C.violet} style={{ left: 240, top: 28 }} />
        <WindowMock w={170} h={110} title="Terminal" kind="term" style={{ left: 50, top: 100 }} />
      </MacDisplay>
    </div>
    <div style={{ position: "absolute", left: 960, top: 330 }}>
      <Tablet width={290} height={186}>
        <WindowMock w={150} h={104} title="Chat" kind="chat" style={{ left: 110, top: 30 }} />
        <div
          style={{
            position: "absolute",
            left: 22,
            top: 34,
            width: 70,
            height: 70,
            borderRadius: 18,
            background: gradient,
            opacity: 0.9,
          }}
        />
      </Tablet>
    </div>
  </AbsoluteFill>
);
