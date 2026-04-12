import './DetailPage.css';

const images = ['image 1', 'image 2', 'Image 3', 'Image 4'];
const details = ['Original Price', 'Brand', 'Known issues'];

export default function DetailPage({ title = 'Badminton Racket' }) {
  return (
    <div className="detail-page">
      <h1 className="detail-title">{title}</h1>

      <div className="image-grid">
        {images.map((label) => (
          <div key={label} className="image-card">
            <span className="image-label">{label}</span>
          </div>
        ))}
      </div>

      <div className="detail-list">
        {details.map((item) => (
          <button key={item} className="detail-btn">
            {item}
          </button>
        ))}
      </div>
    </div>
  );
}
