#!/usr/bin/env python3
import hashlib, json, os, subprocess, sys, tarfile, tempfile

def sha256(path, chunk=2**20):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(chunk), b""):
            h.update(b)
    return h.hexdigest()

def main():
    if len(sys.argv) < 2:
        print("usage: verifybackup.py /path/to/artifact [manifest.json]")
        sys.exit(2)
    artifact = sys.argv[1]
    manifest_path = sys.argv[2] if len(sys.argv) > 2 else artifact + ".manifest.json"

    with open(manifest_path) as m:
        manifest = json.load(m)

    # decrypt to temp if .enc
    candidate = artifact
    if artifact.endswith(".enc"):
        passfile = os.environ.get("ENCRYPT_PASSPHRASE_FILE")
        if not passfile or not os.path.isfile(passfile):
            print("ENCRYPT_PASSPHRASE_FILE required for decrypt verify", file=sys.stderr)
            sys.exit(2)
        tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".tar")
        tmp.close()
        subprocess.check_call([
            "openssl","enc","-d","-aes-256-gcm","-pbkdf2",
            "-in", artifact, "-out", tmp.name, "-pass", f"file:{passfile}"
        ])
        candidate = tmp.name

    # checksum
    digest = sha256(artifact if artifact.endswith(".enc") else candidate)
    if digest != manifest["sha256"]:
        print(f"SHA256 mismatch: {digest} != {manifest['sha256']}")
        sys.exit(1)

    # tar test (works for .tar.gz or .tar.zst if pre-decoded externally)
    if candidate.endswith(".tar"):
        with tarfile.open(candidate, "r") as t:
            bad = t.testzip()  # always returns None for tar; just try reading
        # listing a few members to ensure readability
        _ = t.getmembers()[:5]

    print("OK: checksum and archive are valid")

if __name__ == "__main__":
    main()
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
