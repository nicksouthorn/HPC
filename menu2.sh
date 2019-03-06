#!/bin/bash
echo "Select Option:

1) Display current Lustre settings
2) Reset Lustre settings to default
3) Tune Lustre for Abaqus
4) Exit

"


read n
case $n in
1) echo "option 1"   ;;
2) echo "option 2"   ;;
3) echo "option 3"   ;;
4) echo "option 4"   ;;
*) echo "invalid option" ;;
esac

