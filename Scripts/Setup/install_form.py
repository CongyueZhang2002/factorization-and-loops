#!/usr/bin/env python3
"""Install the pinned upstream Linux FORM runtime in the existing add-on tree."""
from pathlib import Path
import hashlib,json,os,platform,shutil,subprocess,tarfile,tempfile,urllib.request
VERSION="5.0.1"
def main():
    if platform.system()!="Linux" or platform.machine()!="x86_64":
        raise SystemExit("This installer currently supports Linux x86_64 only.")
    root=Path(__file__).resolve().parents[2]
    destination=root/"Addon/Other_Addon/FORM"
    destination.mkdir(parents=True,exist_ok=True)
    url=f"https://github.com/form-dev/form/releases/download/v{VERSION}/form-{VERSION}-x86_64-linux.tar.gz"
    with tempfile.TemporaryDirectory(prefix="feynfacet-form-") as scratch:
        archive=Path(scratch)/"form.tar.gz"
        req=urllib.request.Request(url,headers={"User-Agent":"FeynFacet-runtime-setup"})
        with urllib.request.urlopen(req,timeout=60) as response,archive.open("wb") as out:
            shutil.copyfileobj(response,out)
        digest=hashlib.file_digest(archive.open("rb"),"sha256").hexdigest()
        with tarfile.open(archive) as tar:
            binaries=[m for m in tar.getmembers() if m.isfile() and Path(m.name).name in {"form","tform"}]
            if sorted(Path(m.name).name for m in binaries)!=["form","tform"]:
                raise SystemExit("Unexpected upstream runtime archive.")
            for member in binaries:
                target=destination/"bin"/Path(member.name).name
                target.parent.mkdir(exist_ok=True)
                with tar.extractfile(member) as source,target.open("wb") as out:
                    shutil.copyfileobj(source,out)
                target.chmod(0o755)
                if shutil.which("strip"):
                    subprocess.run(["strip",str(target)],check=True)
            licenses=[m for m in tar.getmembers() if m.isfile() and Path(m.name).name in {"COPYING","LICENSE"}]
            for member in licenses[:1]:
                (destination/"COPYING").write_bytes(tar.extractfile(member).read())
        if not (destination/"COPYING").exists():
            license_url=f"https://raw.githubusercontent.com/form-dev/form/v{VERSION}/COPYING"
            with urllib.request.urlopen(license_url,timeout=30) as response:
                (destination/"COPYING").write_bytes(response.read())
        version=subprocess.run([str(destination/"bin/form"),"-v"],check=True,capture_output=True,text=True).stdout.strip()
        metadata={"Version":VERSION,"Source":url,"SourceArchiveSHA256":digest,"VersionOutput":version,
                  "License":"GPL-3.0-or-later","SourceCode":f"https://github.com/form-dev/form/releases/download/v{VERSION}/form-{VERSION}.tar.gz"}
        (destination/"runtime.json").write_text(json.dumps(metadata,indent=2)+"\n")
    print(version)
    print(destination)
if __name__=="__main__":main()
