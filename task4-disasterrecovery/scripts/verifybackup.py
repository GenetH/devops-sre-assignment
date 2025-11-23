#!/usr/bin/env python3
# verifybackup.py – nightly verification (checksum, optional tar-list)
import os, sys, subprocess, tempfile, glob

DEST = os.environ.get("BACKUP_DEST")
if not DEST: print("Set BACKUP_DEST", file=sys.stderr); sys.exit(2)
QUICK = "--quick" in sys.argv

def run(cmd): return subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

def list_local():
    files = glob.glob(os.path.join(DEST, "backup_*.tar.gz*"))
    return sorted(os.path.basename(f) for f in files)

def list_s3():
    out = run(["aws","s3","ls",DEST]).stdout.decode()
    return sorted([l.split()[-1] for l in out.splitlines() if l.strip().endswith((".tar.gz",".tar.gz.age",".tar.gz.enc"))])

files = list_s3() if DEST.startswith("s3://") else list_local()
if not files: print("No backups found"); sys.exit(3)
target = files[-1]
sha = target.rsplit(".",1)[0] + ".sha256" if target.endswith((".age",".enc")) else target.replace(".tar.gz", "") + ".sha256"

with tempfile.TemporaryDirectory() as td:
    if DEST.startswith("s3://"):
        run(["aws","s3","cp",f"{DEST}/{sha}", td+"/"])
        if not QUICK: run(["aws","s3","cp",f"{DEST}/{target}", td+"/"])
    else:
        run(["cp", os.path.join(DEST, sha), td+"/"])
        if not QUICK: run(["cp", os.path.join(DEST, target), td+"/"])

    os.chdir(td)
    run(["sha256sum","-c",sha])  # raises if mismatch

    if not QUICK and target.endswith(".tar.gz") and os.path.exists(target):
        run(["tar","-tzf",target])  # lists contents to catch corruption

print(f"OK: {target} checksum" + ("" if QUICK else " + tar"))
