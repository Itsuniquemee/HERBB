from PIL import Image

# Open the original logo
logo = Image.open("assets/icons/logo.png")

# Create a new image with white background
# Make the logo 70% of the original size (adjust this percentage as needed)
scale_factor = 0.7  # Change to 0.6 for even smaller, 0.8 for slightly smaller

# Calculate new size
new_width = int(logo.width * scale_factor)
new_height = int(logo.height * scale_factor)

# Resize the logo
resized_logo = logo.resize((new_width, new_height), Image.Resampling.LANCZOS)

# Create a new image with the original size and white background
final_image = Image.new('RGBA', (logo.width, logo.height), (255, 255, 255, 255))

# Calculate position to center the resized logo
x = (logo.width - new_width) // 2
y = (logo.height - new_height) // 2

# Paste the resized logo onto the white background
final_image.paste(resized_logo, (x, y), resized_logo if resized_logo.mode == 'RGBA' else None)

# Save the new logo
final_image.save("assets/icons/logo_small.png")
print(f"Created logo_small.png with {int((1-scale_factor)*100)}% padding")
print(f"Original size: {logo.width}x{logo.height}")
print(f"Logo size in icon: {new_width}x{new_height}")
