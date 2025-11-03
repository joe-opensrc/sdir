### scan dir -- sd
----
 
  Another "Hideously Functional" shell script, brought to you by Folly Projects Inc. :D

  It uses GNU 'find' and (optionally) 'du' to list files, displaying their type.
  It dereferences symlinks so you get the file type of the thing being pointed at.

  It's also quite a bit slower than 'ls' and has fewer options, but it does have colors + sorting ;)

#### USAGE 
---

      sd [-S] [-L <depth>] [-cfhsuv]

      -F <regex>  :=  filter filetype by regex
      -S          :=  do not sort output (use "found" order)
      -L <depth>  :=  limit depth of call to find + du (aka., max-*depth)
      -c          :=  /don't/ colorize output 
      -f          :=  sort filename alphabetically
      -h          :=  this help message ;) 
      -s          :=  sort by size
      -u          :=  use GNU 'du' to calculate size ( slows things down, but is informative :) )
      -v          :=  sort filename via natural-sort 
      

    > sd -s -u -c
    ModTime           FileType            Size  Perms  FileName
    2025-10-08 11:33  inode/x-empty          0  0644   emptyfile1
    2025-10-08 11:33  inode/directory        0  0755   emptydir1
    2025-10-08 11:35  text/x-shellscript  4.1K  0755   sd.sh
    2025-10-08 11:40  text/csv             53K  0644   some.csv
    2025-10-08 11:37  inode/directory      10M  0755   dir2
                                           ^^^
                                            note that the directory's contents have 
                                            been taken into account when calculating its size
                                            

#### CAVEATS
---

    It's slow; but I wanted to use shell + awk :)

