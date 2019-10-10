#!/bin/bash
ABSOLUTE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo '#!/bin/bash' > $ABSOLUTE_PATH/installPlugins.sh
code --list-extensions | xargs -L 1 echo code --install-extension >> $ABSOLUTE_PATH/installPlugins.sh
chmod u+x $ABSOLUTE_PATH/installPlugins.sh
echo $ABSOLUTE_PATH/installPlugins.sh
