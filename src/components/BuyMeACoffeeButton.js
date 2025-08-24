import React from 'react';

const BuyMeACoffeeButton = () => {
  const handleClick = () => {
    window.open('https://buymeacoffee.com/demonwarriortech', '_blank');
  };

  return (
    <div style={{ textAlign: 'center', margin: '20px 0' }}>
      <button
        onClick={handleClick}
        style={{
          backgroundColor: '#5F7FFF',
          color: 'white',
          padding: '12px 24px',
          borderRadius: '25px',
          fontSize: '16px',
          fontWeight: 'bold',
          fontFamily: 'system-ui, -apple-system, sans-serif',
          boxShadow: '0 4px 12px rgba(0, 0, 0, 0.15)',
          transition: 'all 0.2s ease',
          display: 'inline-flex',
          alignItems: 'center',
          gap: '8px',
          border: 'none',
          cursor: 'pointer',
          textDecoration: 'none',
        }}
        onMouseEnter={(e) => {
          e.currentTarget.style.transform = 'scale(1.05)';
          e.currentTarget.style.backgroundColor = '#4F6FEF';
        }}
        onMouseLeave={(e) => {
          e.currentTarget.style.transform = 'scale(1)';
          e.currentTarget.style.backgroundColor = '#5F7FFF';
        }}
        title="Support me on Buy me a coffee!"
      >
        <span style={{ fontSize: '18px' }}>☕</span>
        Buy me a coffee
      </button>
    </div>
  );
};

export default BuyMeACoffeeButton;
