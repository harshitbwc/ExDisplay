import React from "react";
import { AbsoluteFill, Easing, interpolate, useCurrentFrame } from "remotion";
import { C, font, gradient } from "../theme";
import { Finger, Tablet, WindowMock, tabletScreen } from "../Devices";

const TAB = { x: 130, y: 270, w: 960, h: 600 };
const S = tabletScreen(TAB.w, TAB.h);

const clamp = {
  extrapolateLeft: "clamp",
  extrapolateRight: "clamp",
} as const;
const ease = Easing.bezier(0.45, 0, 0.2, 1);

const gestures = [
  { title: "Tap & drag", sub: "One finger clicks and drags", from: 0 },
  { title: "Scroll", sub: "Two fingers pan", from: 90 },
  { title: "Switch desktops", sub: "Three fingers swipe", from: 180 },
];

const GestureCard: React.FC<{
  title: string;
  sub: string;
  from: number;
  to: number;
  index: number;
}> = ({ title, sub, from, to, index }) => {
  const frame = useCurrentFrame();
  const active = frame >= from && frame < to;
  const t = interpolate(frame, [from, from + 12], [0, 1], clamp);
  const on = active ? t : 0;
  return (
    <div
      style={{
        padding: "28px 36px",
        borderRadius: 28,
        border: `2px solid ${active ? C.blue : C.line}`,
        background: active ? "rgba(59,130,246,0.14)" : "rgba(22,32,61,0.7)",
        display: "flex",
        alignItems: "center",
        gap: 28,
        opacity: active ? 1 : 0.55,
        scale: 1 + on * 0.02,
      }}
    >
      <div
        style={{
          width: 64,
          height: 64,
          borderRadius: 20,
          background: gradient,
          display: "grid",
          placeItems: "center",
          color: "#fff",
          fontSize: 34,
          fontWeight: 800,
          flexShrink: 0,
        }}
      >
        {index + 1}
      </div>
      <div>
        <div style={{ fontSize: 50, fontWeight: 800, color: C.text }}>
          {title}
        </div>
        <div style={{ fontSize: 34, fontWeight: 500, color: C.muted }}>
          {sub}
        </div>
      </div>
    </div>
  );
};

export const Touch: React.FC = () => {
  const frame = useCurrentFrame();

  // --- Phase 1 (0-90): one finger taps a button, then drags a window
  const tapT = interpolate(frame, [4, 30], [0, 1], { ...clamp, easing: ease });
  const dragT = interpolate(frame, [44, 84], [0, 1], { ...clamp, easing: ease });
  const f1x = frame < 44 ? interpolate(tapT, [0, 1], [90, 200]) : 200 + dragT * 330;
  const f1y = frame < 44 ? interpolate(tapT, [0, 1], [380, 250]) : 250 + dragT * 70;
  const p1 = interpolate(frame, [0, 6, 84, 92], [0, 1, 1, 0], clamp);
  const ripple = interpolate(frame, [30, 50], [0, 1], clamp);

  // --- Phase 2 (90-180): two fingers scroll the list up
  const sT = interpolate(frame, [98, 168], [0, 1], { ...clamp, easing: ease });
  const p2 = interpolate(frame, [90, 98, 168, 178], [0, 1, 1, 0], clamp);
  const scrollY = -sT * 170;

  // --- Phase 3 (180-270): three fingers swipe, desktops slide
  const wT = interpolate(frame, [192, 250], [0, 1], { ...clamp, easing: ease });
  const p3 = interpolate(frame, [180, 192, 250, 262], [0, 1, 1, 0], clamp);
  const slide = -wT * S.w;

  const page1Opacity = interpolate(frame, [86, 98], [1, 0.0], clamp);

  return (
    <AbsoluteFill style={{ fontFamily: font }}>
      <div style={{ position: "absolute", left: TAB.x, top: TAB.y }}>
        <Tablet width={TAB.w} height={TAB.h}>
          {/* Desktop 1 + 2, side by side, slid by the 3-finger swipe */}
          <div
            style={{
              position: "absolute",
              left: 0,
              top: 0,
              width: S.w * 2,
              height: S.h,
              translate: `${slide}px 0px`,
            }}
          >
            <div style={{ position: "absolute", left: 0, top: 0, width: S.w, height: S.h }}>
              {/* Phase 1: tap target + draggable window */}
              <div style={{ opacity: page1Opacity }}>
                <div
                  style={{
                    position: "absolute",
                    left: 150,
                    top: 205,
                    padding: "14px 28px",
                    borderRadius: 14,
                    background: ripple > 0 && ripple < 1 ? C.mint : "rgba(255,255,255,0.18)",
                    color: "#fff",
                    fontSize: 26,
                    fontWeight: 700,
                  }}
                >
                  Tap
                </div>
                <WindowMock
                  w={250}
                  h={170}
                  title="Notes"
                  kind="doc"
                  accent={C.violet}
                  style={{ left: 90 + dragT * 330, top: 240 + dragT * 70 }}
                />
              </div>
              {/* Phase 2: scrolling list */}
              <div
                style={{
                  position: "absolute",
                  left: 0,
                  top: 0,
                  width: S.w,
                  height: S.h,
                  opacity: interpolate(frame, [90, 102], [0, 1], clamp),
                }}
              >
                <div
                  style={{
                    position: "absolute",
                    left: 220,
                    top: 40,
                    width: 440,
                    translate: `0px ${scrollY}px`,
                    display: "flex",
                    flexDirection: "column",
                    gap: 16,
                  }}
                >
                  {[0, 1, 2, 3, 4, 5, 6].map((i) => (
                    <div
                      key={i}
                      style={{
                        height: 100,
                        borderRadius: 18,
                        background: i % 2 ? "rgba(255,255,255,0.88)" : "rgba(255,255,255,0.72)",
                        display: "flex",
                        alignItems: "center",
                        gap: 18,
                        padding: "0 22px",
                      }}
                    >
                      <div style={{ width: 52, height: 52, borderRadius: 14, background: i % 3 === 0 ? C.blue : i % 3 === 1 ? C.violet : C.mint }} />
                      <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 10 }}>
                        <div style={{ height: 14, width: `${80 - i * 6}%`, borderRadius: 8, background: "#B8C2DC" }} />
                        <div style={{ height: 10, width: "50%", borderRadius: 8, background: "#D3DAEC" }} />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
            <div
              style={{
                position: "absolute",
                left: S.w,
                top: 0,
                width: S.w,
                height: S.h,
                background: "linear-gradient(135deg, #0F3D5E, #1B6A8F 60%, #2A8FA8)",
              }}
            >
              <WindowMock w={330} h={230} title="Browser" kind="doc" accent={C.mint} style={{ left: 120, top: 120 }} />
              <WindowMock w={290} h={200} title="Chat" kind="chat" style={{ left: 500, top: 190 }} />
            </div>
          </div>

          {/* Desktop indicator dots */}
          <div style={{ position: "absolute", bottom: 18, left: 0, right: 0, display: "flex", justifyContent: "center", gap: 12 }}>
            {[0, 1].map((i) => (
              <div
                key={i}
                style={{
                  width: 14,
                  height: 14,
                  borderRadius: "50%",
                  background: "#fff",
                  opacity: i === 0 ? 1 - wT * 0.65 : 0.35 + wT * 0.65,
                }}
              />
            ))}
          </div>

          {/* Fingers */}
          <Finger x={f1x} y={f1y} opacity={p1} scale={frame >= 30 && frame < 44 ? 0.88 : 1} />
          {ripple > 0 && ripple < 1 ? (
            <div
              style={{
                position: "absolute",
                left: 200 - 60,
                top: 250 - 60,
                width: 120,
                height: 120,
                borderRadius: "50%",
                border: `4px solid ${C.mint}`,
                opacity: 1 - ripple,
                scale: 0.5 + ripple,
              }}
            />
          ) : null}
          <Finger x={430} y={420 - sT * 170} opacity={p2} />
          <Finger x={510} y={440 - sT * 170} opacity={p2} />
          <Finger x={600 + (1 - wT) * 190} y={330} opacity={p3} />
          <Finger x={670 + (1 - wT) * 190} y={300} opacity={p3} />
          <Finger x={740 + (1 - wT) * 190} y={330} opacity={p3} />
        </Tablet>
      </div>

      <div
        style={{
          position: "absolute",
          left: 120,
          top: 96,
          fontSize: 84,
          fontWeight: 800,
          letterSpacing: -2,
          color: C.text,
        }}
      >
        Touch works like a trackpad.
      </div>

      <div
        style={{
          position: "absolute",
          left: 1170,
          top: 290,
          width: 640,
          display: "flex",
          flexDirection: "column",
          gap: 22,
        }}
      >
        {gestures.map((g, i) => (
          <GestureCard key={g.title} {...g} to={g.from + 90} index={i} />
        ))}
      </div>
    </AbsoluteFill>
  );
};
