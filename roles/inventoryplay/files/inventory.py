import os
import subprocess

debug = 0

def read_all_file(dir):

    hash = {};
    if not dir:
        return hash

    try:
        isdir = os.path.isdir(dir)
    except Exception as e:
        print("Error checking status of a directory","error:",e)
        return hash

    if not isdir:
        return hash

    files = [];
    with os.scandir(dir) as it:
        for entry in it:
            if debug: print("entry:",entry)
            if not entry.is_file():
                continue

            if entry.name.startswith('.'):
                continue
           
            #basename = os.path.basename(entry.name)
            #files.append(basename)
            files.append(os.path.join(dir, entry.name))

    for file in files:
        array = [];
        if debug: print("file:",file)
        try:
             f = open(os.fsdecode(file), "r")
        except Exception as e:
            print("Error reading file", file, " error: ", e)
            continue
        else:
            for line in f:
                array.append(line.strip())

            f.close()
            hash[os.path.basename(file)] = array

    return hash

if __name__ == "__main__": 
    hash = read_all_file("/tmp/bepa")
    print("hash:", hash)
