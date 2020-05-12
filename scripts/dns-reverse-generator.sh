#!/usr/bin/env bash
set -e

FILE="dns/db.10.127"
LO_TEMP="$(mktemp)"

if [[ "$(uname)" = *BSD ]]; then
	TAC=gtac
else
	TAC=tac
fi

print_record()
{
	printf "%s\tIN\tPTR\t%s\n" "$1" "$2"
}

ipcalc()
{
	local subnet="$1"
	local add="$2"

	REV="$(echo -n "${subnet%,*}." | "$TAC" -s .)"
	REV="${REV%.*.*.}"

	echo "$[ ${REV%.*} + $add ].${REV#*.}"
}

# PROGRAM BEGIN

sed -i '/AUTOGENERATED/,$d' "$FILE"
echo '; AUTOGENERATED' >> "$FILE"

(
cd route
for i in *; do
	source "$i"
	if [ "$TYPE" = "LO" ]; then
		ip="${i/,32/}"

		print_record "$(ipcalc "$ip" 0)" "$NAME.neo" >> "$LO_TEMP"
	fi
done
)

{
	echo -e "\n; Loopback Addresses"
	sort -n < "$LO_TEMP"
} >> "$FILE"

rm -f "$LO_TEMP"
