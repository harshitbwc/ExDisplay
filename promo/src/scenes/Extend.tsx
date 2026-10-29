import React from "react";
import { AbsoluteFill, Easing, interpolate, useCurrentFrame } from "remotion";
import { C, font } from "../theme";
import {
  Cursor,
  MacDisplay,
  Tablet,
  WindowMock,
  macDesktop,
  tabletScreen,
} from "../Devices";

// Global layout (1920x1080)
const MAC = { x: 110, y: 250, w: 900, h: 562 };
const TAB = { x: 1250, y: 330, w: 560, h: 350 };
const macD = macDesktop(MAC.w, MAC.h);
const tabS = tabletScreen(TAB.w, TAB.h);
// Top-left of each clipped surface in global coordinates
const macOrigin = { x: MAC.x + macD.x, y: MAC.y + macD.y };
const tabOrigin = { x: TAB.x + tabS.x, y: TAB.y + tabS.y };

const CABLE = "M1010 580 C 1110 580, 1150 505, 1250 505";

const Caption: React.FC<{ from: number; to: number; children: string }> = ({
  from,
  to,
  children,
}) => {
  const frame = useCurrentFrame();
  const opacity = interpolate(
    frame,
    [from, from + 14, to - 14, to],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );
  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        top: 96,
        textAlign: "center",
        fontSize: 84,
        fontWeight: 800,
        letterSpacing: -2,
        color: C.text,
        opacity,
        translate: `0px ${interpolate(opacity, [0, 1], [24, 0])}px`,
      }}
    >
      {children}
    </div>
  );
};

export const Extend: React.FC = () => {
  const frame = useCurrentFrame();

  // 0-90: cable draws and the tablet wakes up
  const draw = interpolate(frame, [8, 60], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(0.45, 0, 0.2, 1),
  });
  const wake = interpolate(frame, [58, 84], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const pulse = interpolate(frame % 50, [0, 50], [-300, 380]);

  // 100-190: drag the chat window from the Mac onto the tablet
  const drag = interpolate(frame, [104, 184], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(0.5, 0, 0.2, 1),
  });
  const win = {
    w: 300,
    h: 210,
    x: interpolate(drag, [0, 1], [330, 1340]),
    y: interpolate(drag, [0, 1], [330, 400]),
  };
  const grabbed = frame >= 96 && frame <= 190;
  const cursorIn = interpolate(frame, [70, 96], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const cursorX = interpolate(
    frame,
    [70, 96],
    [win.x + 420, win.x + 90],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
  );

  const winOnMac = (
    <WindowMock
      w={win.w}
      h={win.h}
      title="Chat"
      kind="chat"
      style={{
        left: win.x - macOrigin.x,
        top: win.y - macOrigin.y,
        scale: interpolate(drag, [0, 0.1, 1], [1, 1.04, 1]),
      }}
    />
  );
  const winOnTablet = (
    <WindowMock
      w={win.w}
      h={win.h}
      title="Chat"
      kind="chat"
      style={{ left: win.x - tabOrigin.x, top: win.y - tabOrigin.y }}
    />
  );

  return (
    <AbsoluteFill style={{ fontFamily: font }}>
      <Caption from={0} to={96}>
        Plug in the cable.
      </Caption>
      <Caption from={96} to={202}>
        Drag windows over.
      </Caption>
      <Caption from={202} to={270}>
        A real extra display.
      </Caption>

      <div style={{ position: "absolute", left: MAC.x, top: MAC.y }}>
        <MacDisplay width={MAC.w} height={MAC.h}>
          <WindowMock
            w={340}
            h={250}
            title="Notes"
            kind="doc"
            accent={C.violet}
            style={{ left: 480, top: 60 }}
          />
          <WindowMock
            w={290}
            h={190}
            title="Terminal"
            kind="term"
            style={{ left: 120, top: 300 }}
          />
          {winOnMac}
        </MacDisplay>
      </div>

      <div style={{ position: "absolute", left: TAB.x, top: TAB.y }}>
        <Tablet width={TAB.w} height={TAB.h}>
          <div style={{ position: "absolute", inset: 0, opacity: wake }}>
            <WindowMock
              w={250}
              h={160}
              title="Docs"
              kind="list"
              accent={C.mint}
              style={{ left: 260, top: 130, opacity: interpolate(frame, [188, 214], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }) }}
            />
            {winOnTablet}
          </div>
          <div
            style={{
              position: "absolute",
              inset: 0,
              background: "#05070F",
              opacity: 1 - wake,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color: C.muted,
              fontSize: 22,
              fontWeight: 600,
            }}
          >
            {draw > 0.95 ? "Connecting…" : ""}
          </div>
        </Tablet>
      </div>

      <svg
        width={1920}
        height={1080}
        style={{ position: "absolute", inset: 0 }}
        fill="none"
      >
        <path
          d={CABLE}
          stroke={C.line}
          strokeWidth={10}
          strokeLinecap="round"
          pathLength={1}
          strokeDasharray={1}
          strokeDashoffset={1 - draw}
        />
        <path
          d={CABLE}
          stroke={C.mint}
          strokeWidth={10}
          strokeLinecap="round"
          strokeDasharray="60 340"
          strokeDashoffset={-pulse}
          opacity={wake}
          style={{ filter: `drop-shadow(0 0 8px ${C.mint})` }}
        />
      </svg>

      <div
        style={{
          position: "absolute",
          left: MAC.x,
          top: MAC.y + MAC.h + 120,
          width: MAC.w,
          textAlign: "center",
          fontSize: 34,
          fontWeight: 600,
          color: C.muted,
        }}
      >
        Your Mac
      </div>
      <div
        style={{
          position: "absolute",
          left: TAB.x,
          top: TAB.y + TAB.h + 44,
          width: TAB.w,
          textAlign: "center",
          fontSize: 34,
          fontWeight: 600,
          color: C.muted,
        }}
      >
        Your tablet
      </div>

      {frame >= 70 && frame <= 214 ? (
        <div style={{ opacity: cursorIn }}>
          <Cursor
            x={grabbed && frame > 96 ? win.x + 90 : cursorX}
            y={grabbed && frame > 96 ? win.y + 14 : win.y + 14}
          />
        </div>
      ) : null}
    </AbsoluteFill>
  );
};
