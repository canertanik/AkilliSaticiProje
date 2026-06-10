import qrcode
import fitz  # PyMuPDF
import os

url = "https://youtu.be/3uau9JbjlnI"
qr_path = r"C:\Users\caner44\Desktop\PROJEM\qr_code.png"
pdf_path = r"C:\Users\caner44\Desktop\PROJEM\Akilli_Satici_Poster_50x70_v2kesin.pdf"
output_pdf_path = r"C:\Users\caner44\Desktop\PROJEM\Akilli_Satici_Poster_50x70_v4.pdf"

try:
    print("Generating QR code...")
    # Generate QR code
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=20,
        border=2, # made border smaller
    )
    qr.add_data(url)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    img.save(qr_path)
    print("QR code saved to:", qr_path)

    print("Opening PDF...")
    # Open PDF
    doc = fitz.open(pdf_path)
    page = doc[0] # first page

    # Get page dimensions
    rect = page.rect
    width = rect.width
    height = rect.height
    print(f"PDF Dimensions: {width} x {height}")

    # Calculate coordinates for bottom-right corner
    # Make it smaller to fit nicely in the empty space without overlapping SQL Server
    qr_size = 110 # points (smaller)
    margin_x = 60 # margin from right edge
    margin_y = 60 # margin from bottom edge (to align with BANÜ emblem)

    x1 = width - margin_x - qr_size
    y1 = height - margin_y - qr_size
    x2 = width - margin_x
    y2 = height - margin_y

    # Define the rectangle where the image will be inserted
    image_rect = fitz.Rect(x1, y1, x2, y2)

    print(f"Inserting image at: {image_rect}")
    # Insert image
    page.insert_image(image_rect, filename=qr_path)

    # Save output
    doc.save(output_pdf_path)
    doc.close()
    print("Successfully saved the modified PDF to:", output_pdf_path)
    
except Exception as e:
    print("An error occurred:", e)
