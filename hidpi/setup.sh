#!/bin/sh
if [ ! -f /etc/profile.d/gdk-scale.sh ]; then
cat <<EOF | sudo tee /etc/profile.d/gdk-scale.sh
#!/bin/sh
export GDK_DPI_SCALE=1.5
EOF
fi
