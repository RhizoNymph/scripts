from flask import Flask, request, jsonify, send_file
import subprocess
import os
import zipfile
import tempfile
import shutil
import re

app = Flask(__name__)

def update_markdown_links(markdown_content, image_folder):
    # Update image links in the markdown content
    pattern = r'!\[(.*?)\]\((.*?)\)'
    def replace_link(match):
        alt_text, image_path = match.groups()
        new_path = os.path.join(image_folder, os.path.basename(image_path))
        return f'![{alt_text}]({new_path})'
    
    return re.sub(pattern, replace_link, markdown_content)

@app.route('/convert', methods=['POST'])
def convert_pdf():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    if file:
        with tempfile.TemporaryDirectory() as temp_dir:
            # Save the file to the temporary directory
            input_path = os.path.join(temp_dir, file.filename)
            file.save(input_path)

            # Define output path
            output_folder = os.path.join(temp_dir, 'output')
            os.makedirs(output_folder, exist_ok=True)

            # Run the marker conversion command
            command = f"marker_single {input_path} {output_folder} --batch_multiplier 2 --langs English"
            process = subprocess.run(command, shell=True, capture_output=True, text=True)

            if process.returncode == 0:
                # Create an 'images' folder
                images_folder = os.path.join(os.path.join(output_folder, file.filename.replace('.pdf', '')), 'images')
                os.makedirs(images_folder, exist_ok=True)

                # Move all image files to the 'images' folder
                for root, _, files in os.walk(output_folder):
                    for file in files:
                        if file.lower().endswith(('.png', '.jpg', '.jpeg', '.gif')):
                            old_path = os.path.join(root, file)
                            new_path = os.path.join(images_folder, file)
                            shutil.move(old_path, new_path)

                # Update markdown files to reflect new image locations
                for root, _, files in os.walk(output_folder):
                    for file in files:
                        if file.lower().endswith('.md'):
                            md_path = os.path.join(root, file)
                            with open(md_path, 'r', encoding='utf-8') as md_file:
                                content = md_file.read()
                            
                            updated_content = update_markdown_links(content, 'images')
                            
                            with open(md_path, 'w', encoding='utf-8') as md_file:
                                md_file.write(updated_content)

                # Zip the output folder and send it back
                zip_path = os.path.join(temp_dir, 'converted_files.zip')
                with zipfile.ZipFile(zip_path, 'w') as zipf:
                    for root, _, files in os.walk(output_folder):
                        for file in files:
                            file_path = os.path.join(root, file)
                            arcname = os.path.relpath(file_path, output_folder)
                            zipf.write(file_path, arcname)

                return send_file(zip_path, as_attachment=True, download_name='converted_files.zip')
            else:
                # Failure: Send back the error
                return jsonify({"error": "Conversion failed", "details": process.stderr}), 500

if __name__ == '__main__':
    app.run(debug=True)
