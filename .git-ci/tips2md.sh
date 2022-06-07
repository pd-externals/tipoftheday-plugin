#!/bin/sh

cd "${0%/*}/.."

gettag() {
    grep -E "^$2[[:space:]]" "$1" | sed -e "s|^$2[[:space:]]*||"
}

markdownify() {
    local title
    local description
    local url
    local img
    
    title=$(gettag "$1" TITLE | sed -e 's|"|\\"|g')
    description=$(gettag "$1" DETAIL)
    url=$(gettag "$1" URL | tail -1)

    cat <<EOF
---
title: "${title}"
---

${description}


EOF
    img="${1%.txt}".gif
    if [  -e "${img}" ]; then
        img=${img##*/}
        echo "![$title]($img)"
    fi

    if [ -n "${url}" ]; then
        echo "[More info...](${url})"
    fi
}

for tip in tips/*.txt; do
    if [ ! -e "${tip}" ]; then continue; fi
    t=${tip%.txt}
    t=${t##*/}
    echo "adding tip ${tip}"
    mkdir -p "content/tips/${t}"
    t="content/tips/${t}"
    markdownify "${tip}" > "${t}/index.md"
    [ ! -e "${tip%.txt}.gif" ] || cp "${tip%.txt}.gif" "${t}/"
done
