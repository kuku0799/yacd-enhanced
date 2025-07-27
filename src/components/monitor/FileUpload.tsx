import React, { useRef } from 'react';

interface FileUploadProps {
  onUpload: (file: File) => Promise<void>;
}

export const FileUpload: React.FC<FileUploadProps> = ({ onUpload }) => {
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      await onUpload(file);
    }
  };

  const handleDrop = async (event: React.DragEvent) => {
    event.preventDefault();
    const files = event.dataTransfer.files;
    if (files.length > 0) {
      await onUpload(files[0]);
    }
  };

  const handleDragOver = (event: React.DragEvent) => {
    event.preventDefault();
  };

  return (
    <div 
      className="file-upload"
      onDrop={handleDrop}
      onDragOver={handleDragOver}
    >
      <div className="upload-area">
        <input
          ref={fileInputRef}
          type="file"
          accept=".txt,.yaml,.yml"
          onChange={handleFileSelect}
          style={{ display: 'none' }}
        />
        <button 
          onClick={() => fileInputRef.current?.click()}
          className="btn btn-secondary"
        >
          📁 选择节点文件
        </button>
        <p className="upload-hint">
          或拖拽文件到此处
        </p>
      </div>
    </div>
  );
}; 