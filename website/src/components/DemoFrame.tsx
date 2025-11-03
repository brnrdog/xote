import React from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';

interface DemoFrameProps {
  route: string;
  title: string;
  minHeight?: string;
}

export default function DemoFrame({ route, title, minHeight = '600px' }: DemoFrameProps): React.JSX.Element {
  const demoUrl = useBaseUrl(`demos${route}.html`);

  return (
    <div style={{
      width: '100%',
      minHeight: minHeight,
      border: '1px solid var(--ifm-color-emphasis-300)',
      borderRadius: '8px',
      overflow: 'hidden',
      backgroundColor: '#fafaf9'
    }}>
      <iframe
        src={demoUrl}
        title={title}
        style={{
          width: '100%',
          height: minHeight,
          border: 'none',
        }}
        loading="lazy"
        allow="scripts"
      />
    </div>
  );
}
