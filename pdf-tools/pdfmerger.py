from pypdf import PdfWriter
import sys
import os

def merge_pdfs(output_file, input_files):
	merger = PdfWriter()

	for pdf in input_files:
		if not os.path.exists(pdf):
			print(f"File not found: {pdf}")
			continue

		print(f"Adding: {pdf}")
		merger.append(pdf)

	with open(output_file, "wb") as f:
		merger.write(f)

	merger.close()
	print(f"\nMerged PDF saved as: {output_file}")


if __name__ == "__main__":
	# Example usage:
	# python merge_pdfs.py output.pdf file1.pdf file2.pdf file3.pdf

	if len(sys.argv) < 3:
		print("Usage:")
		print("python merge_pdfs.py output.pdf input1.pdf input2.pdf ...")
		sys.exit(1)

	output_pdf = sys.argv[1]
	input_pdfs = sys.argv[2:]

merge_pdfs(output_pdf, input_pdfs)
