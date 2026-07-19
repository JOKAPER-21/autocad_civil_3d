import os
import ezdxf

DXF_FOLDER = r"D:\railway\projects\assetLibrary\autocad\tools\mergeDxf\src\v01\python\src"
OUTPUT_FILE = r"D:\railway\projects\assetLibrary\autocad\tools\mergeDxf\src\v01\python\src\output\MERGED_OUTPUT.dxf"

doc_out = ezdxf.new()
msp_out = doc_out.modelspace()

def merge_dxf(file_path, prefix):
    doc = ezdxf.readfile(file_path)
    msp = doc.modelspace()

    for e in msp:
        try:
            new_entity = e.copy()
            new_entity.dxf.layer = f"{prefix}_{e.dxf.layer}"
            msp_out.add_entity(new_entity)
        except:
            pass

for file in os.listdir(DXF_FOLDER):
    if file.lower().endswith(".dxf"):
        path = os.path.join(DXF_FOLDER, file)
        prefix = os.path.splitext(file)[0]

        print("Merging:", file)
        merge_dxf(path, prefix)

doc_out.saveas(OUTPUT_FILE)

print("✔ Merged DXF saved:", OUTPUT_FILE)