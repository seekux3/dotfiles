#!/usr/bin/env bash

function droller() {
    tmp_file="/tmp/droller-temp-file"
    wiki=`stat -f "%N" ~/Dropbox/git/localwiki/_wiki`
    index="$wiki/links.md"
    cmd="$1"
    uri="$2"

    # status, s # 상태를 확인한다
    if [ "$cmd" == "status" -o "$cmd" == "s" ]; then
        head -1 $tmp_file | cut -c 42-
        return 0;
    fi

    # open, o # 현재 지정된 문서를 열어준다
    if [ "$cmd" == "open" -o "$cmd" == "o" ]; then
        head -1 $tmp_file | sed -E "s/^.*] http/http/" | xargs open
        return 0;
    fi

    # 1 # 현재 지정된 문서에 +1
    if [ "$cmd" == "1" ]; then
        hash=`head -1 $tmp_file | cut -d' ' -f1`
        point=`head -1 $tmp_file | awk '{print $2}'`
        newPoint=$(($point + 1))

        sed -i '' "s/$hash $point /$hash $newPoint /" $tmp_file
        sed -i '' -E "s/$hash -?[0-9]{1,} /$hash $newPoint /" $index

        droller s
        return 0;
    fi

    # -1 # 현재 지정된 문서에 -1
    if [ "$cmd" == "-1" ]; then
        hash=`head -1 $tmp_file | cut -d' ' -f1`
        point=`head -1 $tmp_file | awk '{print $2}'`
        newPoint=$(($point - 1))

        sed -i '' "s/$hash $point /$hash $newPoint /" $tmp_file
        sed -i '' -E "s/$hash -?[0-9]{1,} /$hash $newPoint /" $index

        droller s
        return 0;
    fi

    # top, t # 인덱스의 가장 위에 있는 문서를 선택한다
    if [ "$cmd" == "top" -o "$cmd" == "t" ]; then
        head -1 $index > $tmp_file
        droller s
        return 0;
    fi

    # , random, r # 랜덤으로 문서를 선택한다.
    if [ "$cmd" == "" -o "$cmd" == "random" -o "$cmd" == "r" ]; then
        sort -R $index | head -1  > $tmp_file
        droller s
        return 0;
    fi

    # edit # 선택된 문서 정보를 편집한다
    if [ "$cmd" == "edit" -o "$cmd" == "e" ]; then
        vim $tmp_file
        if [ "$?" == "0" ]; then
            hash=`head -1 $tmp_file | cut -d ' ' -f1`
            grep -v $hash $index > $index.old
            head -1 $tmp_file >> $index.old
            cat $index.old > $index
        fi
        droller s
        return 0;
    fi

    # hash # sha1 값을 계산한다
    if [ "$cmd" == "hash" ]; then
        openssl sha1 <<< $uri
        return 0
    fi

    # add, a # 새로운 문서를 추가한다
    if [ "$cmd" == "add" -o "$cmd" == "a" ]; then
        hash=`openssl sha1 <<< $uri`

        grep $hash $index
        if [ "$?" == "0" ]; then
            echo "이미 존재하는 링크입니다."
            grep $hash $index | head -1 > $tmp_file
            return 0;
        else
            printf "%s 0 [] %s\n" $hash $uri >> $index
            echo "링크를 추가하였습니다."
            grep $hash $index | head -1 > $tmp_file
            droller s
            return 0;
        fi

    fi

    # delete, d # 선택된 문서를 삭제한다
    if [ "$cmd" == "delete" -o "$cmd" == "d" ]; then
        hash=`head -1 $tmp_file | cut -d ' ' -f1`
        grep -v $hash $index > $index.old
        cat $index.old > $index
        droller r
        return 0;
    fi

    # help # 도움말을 출력한다
    if [ "$cmd" == "help" -o "$cmd" == "h" ]; then
        egrep "^\s*?# " $BASH_SOURCE | sed 's/^ *#//' | column -ts'#'
    fi

    # http:// # 새로운 문서를 추가한다
    egrep '^https?:' <<< $1 > /dev/null
    if [ "$?" == "0" ]; then
        uri="$1"
        droller add $uri
        return 0
    fi
}