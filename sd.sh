#!/bin/bash

sd(){
  # todo: -C -> color{off,on}
  local useColor="${SD_USE_COLOR:-yes}"
  local useDu=1;
  local sortcmd=( sort -t$'|' -k 1 -V )
  local maxfinddepth=(-maxdepth 1)
  local maxdudepth=(-s)

  local usg="
  ${FUNCNAME[0]} [-S] [-L <depth>] [-cfhsuv]

  "

  local OPTIND= OPTARG= OPTERR=
  while getopts 'cSL:fhsuv' flag
  do
    case "${flag}" in
      c) useColor="";;
      S) sortcmd=( cat - );;
      L) maxfinddepth=(-maxdepth ${OPTARG});
         maxdudepth=(-d ${OPTARG});;
      f) sortcmd=( sort -t$'|' -k 5 -f );;
      h) echo -ne "${usg}"; return 0;;
      s) sortcmd=( sort -t$'|' -k 10 -n );;
      u) useDu=0;;
      v) sortcmd=( sort -t$'|' -k 5 -V );;
      *) echo -ne "${usg}"; return 1;;
    esac
    shift $(( OPTIND -1 ))
    OPTIND=
  done
 
  IFS=$'\n'

  local mts='%TF %TH:%TM'
  local -a fcmd=( find "${@:-.}" -mindepth 1 ${maxfinddepth[@]} -path '*/.*' -prune -o ) 

  # modified-time|ftype-placeholder|size-placeholder|permissions(octal)|filename|ftype|link(ifexists)|leadingDirName(notused?)|filetype(data)|size(data-bytes)
  fcmd+=( -printf "${mts}|x|s|%#m|%P|%y|%l|%h|" )
  fcmd+=( -execdir file -L -0 -0 -N -i -b -n '{}' \; )
  fcmd+=( -printf '|' )

  if [[ ${useDu} -eq 0 ]]
  then 
    fcmd+=( \( -execdir du -x -L -0 -b ${maxdudepth[@]} '{}' \; -a -printf '\n' -o -printf '\n' \) )
  else
    fcmd+=( -printf "%s\n" )
  fi

  IFS=$'\n' "${fcmd[@]}" 2>/dev/null | \
    ${sortcmd[@]} | \
    awk -vOFS="|" -F"|" -vuseDu="${useDu}" -vuseColor=${useColor} \
    '
      BEGIN {
        tcol=1; xcol=2; scol=3; mcol=4; pcol=5; ycol=6; lcol=7; hcol=8;
        i=0;
      }

      function transposeDuColumn(dst){

        if( useDu == "0" ){

          sind=index($NF, "\t");
          if ( sind > 0 ){
            dsize=substr($NF,1,sind-1);
          } else {
            dsize=0
          }
        } else {
          dsize = $NF;
        }

        $dst = dsize;
        NF--;
      }
      
      ###
      function transposeFileTypeCol(dst){
        # file -bi format: "ftypestr[,;] charset=<charset>"
        sci=match($NF, /[,;]/)
        if ( sci > 0 ){
          # extract first field (ie. upto /[,;]/)
          retstr=substr($NF,1,sci-1)
          # M$ofts legacy... ;)
          # try and do clever regex stuff later? ...
          sub(/vnd\.openxmlformats-officedocument\.wordprocessingml\.document/, "openxml-docx", retstr )
          sub(/vnd\.openxmlformats-officedocument\.spreadsheetml\.sheet/,       "openxml-xlsx", retstr )
        }else{
          sci=match($NF, /cannot|inode\/symlink/)
          if ( sci > 0 ){
            retstr="inode/symlink<borked>";
          }
        }
        $dst = retstr
        NF--;
      }

      # can worry about ranges later..
      function applyColor(p,cs,ce){
        $p = sprintf("%s%s%s", cs, $p, ce);
      }

      # stream actions
      {

        transposeDuColumn(scol)
        transposeFileTypeCol(xcol);
 
        if( length($lcol) > 0 ){
          $pcol=sprintf("%s -> %s", $pcol, $lcol);
        } else {
          NF--;
        }

        NF--;

        if( useColor ){

          colorReset="\033[00m";
          colorLink="\033[;38;5;70m";
          colorExec="\033[;38;5;29m";
          colorDir="\033[;38;5;32m";
          colorAppVideo="\033[;38;2;141;108;192m";
          colorTime="\033[;38;2;142;142;142m";

        lval=$ycol
        NF--;
        switch(lval){
          case "l":
            NF--;
            applyColor( tcol, colorTime, colorLink );
            applyColor( 0, colorLink, colorReset );
            break;

          case "d":
            applyColor(tcol, colorTime, colorDir );
            applyColor(0, colorDir, colorReset );
            break;

          case "f":
            if ( $mcol ~ /7/ ){
              applyColor( tcol, colorTime, colorExec );
              applyColor( 0, colorExec, colorReset );
            } else {
              applyColor( tcol, colorTime, colorReset );
              applyColor(0, colorReset, colorReset);
            }

            break;

       }

        switch($xcol){
          case /^video|image/:
            applyColor(tcol, colorTime, colorAppVideo);
            applyColor(0, colorAppVideo, colorReset);
            break;
        }
        # useColor
      } else {
        # strips path-type
        NF--;
      }
      print

      }
    ' | \
    numfmt -d'|' --field 3 --to=iec | \
    column -s'|' -t \
          -N ModTime,FileType,Size,Perms,FileName \
          -R Size 
  IFS=$' \t\n'
}
