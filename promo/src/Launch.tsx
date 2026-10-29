import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { TransitionSeries, linearTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import { C } from "./theme";
import { Hook } from "./scenes/Hook";
import { Reveal } from "./scenes/Reveal";
import { Extend } from "./scenes/Extend";
import { Touch } from "./scenes/Touch";
import { Features } from "./scenes/Features";
import { Steps } from "./scenes/Steps";
import { Cta } from "./scenes/Cta";

// Scene lengths (frames @ 30fps) and the cross-fade between scenes.
export const SCENES = [100, 105, 270, 270, 150, 165, 135];
export const FADE = 15;
export const LAUNCH_FRAMES =
  SCENES.reduce((a, b) => a + b, 0) - FADE * (SCENES.length - 1);

const Background: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(1400px 900px at 20% 0%, ${C.bg2}, ${C.bg} 70%)`,
      }}
    >
      <AbsoluteFill
        style={{
          backgroundImage:
            "radial-gradient(rgba(148,163,184,0.16) 1.5px, transparent 1.5px)",
          backgroundSize: "56px 56px",
          translate: `${interpolate(frame, [0, LAUNCH_FRAMES], [0, -112])}px 0px`,
        }}
      />
    </AbsoluteFill>
  );
};

export const Launch: React.FC = () => {
  const scenes = [Hook, Reveal, Extend, Touch, Features, Steps, Cta];
  return (
    <AbsoluteFill>
      <Background />
      <TransitionSeries>
        {scenes.flatMap((Scene, i) => [
          <TransitionSeries.Sequence key={`s${i}`} durationInFrames={SCENES[i]}>
            <Scene />
          </TransitionSeries.Sequence>,
          ...(i < scenes.length - 1
            ? [
                <TransitionSeries.Transition
                  key={`t${i}`}
                  presentation={fade()}
                  timing={linearTiming({ durationInFrames: FADE })}
                />,
              ]
            : []),
        ])}
      </TransitionSeries>
    </AbsoluteFill>
  );
};
