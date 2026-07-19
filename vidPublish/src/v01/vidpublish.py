
import os,sys,shutil,csv
from datetime import datetime

src=sys.argv[1]
dst_folder=sys.argv[2]
yard=sys.argv[3] if len(sys.argv)>3 else ""

os.makedirs(dst_folder,exist_ok=True)

name,ext=os.path.splitext(os.path.basename(src))
stamp=datetime.now().strftime("%Y%m%d_%H%M%S")
dst=os.path.join(dst_folder,f"{stamp}_{name}{ext}")
shutil.copy2(src,dst)

log=os.path.join(os.path.dirname(dst_folder),"publish_log.csv")
newfile=not os.path.exists(log)
with open(log,"a",newline="",encoding="utf-8") as f:
    w=csv.writer(f)
    if newfile:
        w.writerow(["DateTime","Yard","Source","PublishedFile"])
    w.writerow([stamp,yard,src,dst])

print(dst)
