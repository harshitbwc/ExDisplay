import React from "react";
import { C, font, wallpaper } from "./theme";
import { LogoMark } from "./Logo";

// ---- Mac display ---------------------------------------------------------

const macInset = (w: number) => Math.round(w * 0.014);
const macMenu = (w: number) => Math.round(w * 0.03);

/** Where the desktop area starts inside a MacDisplay, in the device's own pixels. */
export const macDesktop = (w: number, h: number) => ({
  x: macInset(w),
  y: macInset(w) + macMenu(w),
  w: w - 2 * macInset(w),
  h: h - 2 * macInset(w) - macMenu(w),
});

export const MacDisplay: React.FC<{
  width: number;
  height: number;
  stand?: boolean;
  children?: React.ReactNode;
}> = ({ width: w, height: h, stand = true, children }) => {
  const inset = macInset(w);
  const menu = macMenu(w);
  return (
    <div style={{ position: "relative", width: w, height: h }}>
      {stand ? (
        <>
          <div
            style={{
              position: "absolute",
              left: "50%",
              top: h - 4,
              width: w * 0.1,
              height: w * 0.07,
              translate: "-50% 0",
              background: `linear-gradient(${C.line}, #141c38)`,
            }}
          />
          <div
            style={{
              position: "absolute",
              left: "50%",
              top: h + w * 0.066,
              width: w * 0.3,
              height: w * 0.014,
              translate: "-50% 0",
              borderRadius: w * 0.01,
              background: C.line,
            }}
          />
        </>
      ) : null}
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: w * 0.026,
          background: "#080C1A",
          border: `${Math.max(1, w * 0.003)}px solid ${C.line}`,
          boxShadow: "0 30px 80px rgba(0,0,0,0.5)",
        }}
      />
      <div
        style={{
          position: "absolute",
          left: inset,
          top: inset,
          right: inset,
          bottom: inset,
          borderRadius: w * 0.012,
          overflow: "hidden",
          background: wallpaper,
        }}
      >
        <div
          style={{
            position: "absolute",
            left: 0,
            right: 0,
            top: 0,
            height: menu,
            background: "rgba(255,255,255,0.1)",
            display: "flex",
            alignItems: "center",
            justifyContent: "flex-end",
            gap: menu * 0.35,
            paddingRight: menu * 0.6,
          }}
        >
          <LogoMark size={menu * 0.62} id={`menu-${w}`} />
          {[0, 1, 2].map((i) => (
            <div
              key={i}
              style={{
                width: menu * 0.5,
                height: menu * 0.16,
                borderRadius: menu,
                background: "rgba(255,255,255,0.45)",
              }}
            />
          ))}
        </div>
        <div
          style={{
            position: "absolute",
            left: 0,
            right: 0,
            top: menu,
            bottom: 0,
            overflow: "hidden",
          }}
        >
          {children}
        </div>
      </div>
    </div>
  );
};

// ---- Tablet --------------------------------------------------------------

const tabletBezel = (h: number) => Math.round(h * 0.05);

export const tabletScreen = (w: number, h: number) => ({
  x: tabletBezel(h),
  y: tabletBezel(h),
  w: w - 2 * tabletBezel(h),
  h: h - 2 * tabletBezel(h),
});

export const Tablet: React.FC<{
  width: number;
  height: number;
  children?: React.ReactNode;
}> = ({ width: w, height: h, children }) => {
  const b = tabletBezel(h);
  return (
    <div style={{ position: "relative", width: w, height: h }}>
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: h * 0.085,
          background: "#080C1A",
          border: `${Math.max(1, h * 0.006)}px solid ${C.line}`,
          boxShadow: "0 30px 80px rgba(0,0,0,0.5)",
        }}
      />
      <div
        style={{
          position: "absolute",
          left: b,
          top: b,
          right: b,
          bottom: b,
          borderRadius: h * 0.04,
          overflow: "hidden",
          background: wallpaper,
        }}
      >
        {children}
      </div>
      <div
        style={{
          position: "absolute",
          left: b * 0.4,
          top: "50%",
          width: b * 0.2,
          height: b * 0.2,
          translate: "0 -50%",
          borderRadius: "50%",
          background: C.line,
        }}
      />
    </div>
  );
};

// ---- Fake app windows ----------------------------------------------------

type Kind = "chat" | "doc" | "term" | "list";

const Bar: React.FC<{
  w: number | string;
  h: number;
  color?: string;
  style?: React.CSSProperties;
}> = ({ w, h, color = "rgba(255,255,255,0.22)", style }) => (
  <div
    style={{
      width: w,
      height: h,
      borderRadius: h,
      background: color,
      flexShrink: 0,
      ...style,
    }}
  />
);

export const WindowMock: React.FC<{
  w: number;
  h: number;
  title: string;
  kind: Kind;
  accent?: string;
  style?: React.CSSProperties;
}> = ({ w, h, title, kind, accent = C.blue, style }) => {
  const u = w / 320; // all inner sizes scale from a 320px-wide window
  const bar = 34 * u;
  const dark = kind === "term";
  return (
    <div
      style={{
        position: "absolute",
        width: w,
        height: h,
        borderRadius: 12 * u,
        overflow: "hidden",
        background: dark ? "#0E1424" : "#F4F6FB",
        boxShadow: "0 16px 40px rgba(0,0,0,0.45)",
        fontFamily: font,
        ...style,
      }}
    >
      <div
        style={{
          height: bar,
          background: dark ? "#1A2238" : "#E3E8F3",
          display: "flex",
          alignItems: "center",
          gap: 6 * u,
          paddingLeft: 12 * u,
        }}
      >
        {["#FF5F57", "#FEBC2E", "#28C840"].map((c) => (
          <div
            key={c}
            style={{
              width: 9 * u,
              height: 9 * u,
              borderRadius: "50%",
              background: c,
            }}
          />
        ))}
        <span
          style={{
            marginLeft: 8 * u,
            fontSize: 12 * u,
            fontWeight: 600,
            color: dark ? C.muted : "#5A6785",
          }}
        >
          {title}
        </span>
      </div>
      <div
        style={{
          padding: 14 * u,
          display: "flex",
          flexDirection: "column",
          gap: 9 * u,
        }}
      >
        {kind === "chat" &&
          [
            ["left", "62%"],
            ["right", "48%"],
            ["left", "74%"],
            ["right", "36%"],
            ["left", "55%"],
          ].map(([side, width], i) => (
            <Bar
              key={i}
              w={width}
              h={22 * u}
              color={side === "right" ? accent : "#D5DCEC"}
              style={{ alignSelf: side === "right" ? "flex-end" : "flex-start" }}
            />
          ))}
        {kind === "doc" && (
          <>
            <Bar w="55%" h={16 * u} color={accent} />
            {["100%", "92%", "100%", "70%", "96%", "84%", "60%"].map((x, i) => (
              <Bar key={i} w={x} h={9 * u} color="#CBD3E6" />
            ))}
          </>
        )}
        {kind === "term" &&
          [
            ["46%", C.mint],
            ["78%", "#5B6A91"],
            ["64%", "#5B6A91"],
            ["30%", C.mint],
            ["88%", "#5B6A91"],
            ["52%", "#5B6A91"],
          ].map(([x, c], i) => <Bar key={i} w={x} h={8 * u} color={c} />)}
        {kind === "list" &&
          [0, 1, 2, 3, 4].map((i) => (
            <div
              key={i}
              style={{ display: "flex", alignItems: "center", gap: 10 * u }}
            >
              <Bar w={22 * u} h={22 * u} color={i % 2 ? accent : "#D5DCEC"} />
              <Bar w={`${70 - i * 8}%`} h={10 * u} color="#CBD3E6" />
            </div>
          ))}
      </div>
    </div>
  );
};

// ---- Touch + pointer helpers --------------------------------------------

export const Finger: React.FC<{
  x: number;
  y: number;
  size?: number;
  opacity?: number;
  scale?: number;
}> = ({ x, y, size = 64, opacity = 1, scale = 1 }) => (
  <div
    style={{
      position: "absolute",
      left: x - size / 2,
      top: y - size / 2,
      width: size,
      height: size,
      borderRadius: "50%",
      background: "rgba(255,255,255,0.32)",
      border: "3px solid rgba(255,255,255,0.85)",
      boxShadow: "0 6px 24px rgba(0,0,0,0.35)",
      opacity,
      scale,
    }}
  />
);

export const Cursor: React.FC<{ x: number; y: number; size?: number }> = ({
  x,
  y,
  size = 34,
}) => (
  <svg
    width={size}
    height={size * 1.4}
    viewBox="0 0 18 27"
    style={{ position: "absolute", left: x, top: y }}
  >
    <path
      d="M1 1 L1 21 L6 16.5 L9.6 25 L12.8 23.6 L9.2 15.4 L16 15 Z"
      fill="#fff"
      stroke="#0A0F1E"
      strokeWidth="1.6"
      strokeLinejoin="round"
    />
  </svg>
);
