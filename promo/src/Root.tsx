import { Composition, Folder, Still } from "remotion";
import { Launch } from "./Launch";
import { Banner } from "./Banner";
import { LogoLockupStill, LogoMarkStill } from "./LogoStills";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="Launch"
        component={Launch}
        durationInFrames={1105}
        fps={30}
        width={1920}
        height={1080}
      />
      <Folder name="Brand">
        <Still id="Banner" component={Banner} width={1280} height={640} />
        <Still id="LogoMark" component={LogoMarkStill} width={1024} height={1024} />
        <Still id="LogoLockup" component={LogoLockupStill} width={1600} height={640} />
      </Folder>
    </>
  );
};
