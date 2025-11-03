import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import DemoFrame from '@site/src/components/DemoFrame';

export default function ColorMixerDemo(): React.JSX.Element {
  return (
    <Layout
      title="Color Mixer Demo"
      description="RGB color mixing with live preview, format conversions, and palette variations">
      <main className="container margin-vert--lg">
        <div className="row">
          <div className="col">
            <h1>Color Mixer Demo</h1>
            <p className="hero__subtitle">
              Interactive color mixing with RGB sliders and palette generation
            </p>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <DemoFrame route="/color" title="Color Mixer Demo" minHeight="800px" />
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <h2>About This Demo</h2>
            <p>
              This color mixer showcases real-time computed values and effects:
            </p>
            <ul>
              <li><strong>Input Signals</strong> - RGB slider values</li>
              <li><strong>Computed Values</strong> - Hex, HSL, and color name conversions</li>
              <li><strong>Effects</strong> - Live color preview updates</li>
              <li><strong>Complex Computations</strong> - Palette variations and complementary colors</li>
            </ul>
            <p>
              The app uses three signals for RGB values and multiple computed values to
              derive different color formats and palette suggestions. Everything updates
              in real-time as you adjust the sliders.
            </p>
          </div>
        </div>

        <div className="row margin-top--lg">
          <div className="col">
            <div style={{display: 'flex', gap: '1rem', justifyContent: 'center'}}>
              <Link
                className="button button--primary button--lg"
                to="https://github.com/brnrdog/xote/blob/main/demos/ColorMixerApp.res">
                View Source Code
              </Link>
              <Link
                className="button button--secondary button--lg"
                to="/docs/core-concepts/effects">
                Learn About Effects
              </Link>
            </div>
          </div>
        </div>
      </main>
    </Layout>
  );
}
