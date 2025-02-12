#!/usr/bin/env bash

set -u

LIST=(
    # paris
    "tiles/v3/11/1037/704.pbf"
    "tiles/v3/11/1037/705.pbf"
    "tiles/v3/11/1038/704.pbf"
    "tiles/v3/11/1038/705.pbf"
    "tiles/v3/11/1036/704.pbf"
    "tiles/v3/11/1037/703.pbf"
    "tiles/v3/11/1036/705.pbf"
    "tiles/v3/11/1038/703.pbf"
    "tiles/v3/11/1036/703.pbf"

    # paris2
    "tiles/v3/13/4150/2819.pbf"
    "tiles/v3/13/4149/2819.pbf"
    "tiles/v3/13/4150/2818.pbf"
    "tiles/v3/13/4148/2819.pbf"
    "tiles/v3/13/4149/2818.pbf"
    "tiles/v3/13/4148/2818.pbf"
    "tiles/v3/13/4150/2820.pbf"
    "tiles/v3/13/4149/2820.pbf"
    "tiles/v3/13/4149/2817.pbf"
    "tiles/v3/13/4148/2817.pbf"

    # alps
    "tiles/v3/6/34/23.pbf"
    "tiles/v3/6/34/22.pbf"
    "tiles/v3/6/33/23.pbf"
    "tiles/v3/6/33/22.pbf"
    "tiles/v3/6/34/21.pbf"
    "tiles/v3/6/32/23.pbf"
    "tiles/v3/6/32/22.pbf"
    "tiles/v3/6/33/21.pbf"
    "tiles/v3/6/32/21.pbf"

    # us east
    "tiles/v3/5/9/12.pbf"
    "tiles/v3/5/8/12.pbf"
    "tiles/v3/5/9/13.pbf"
    "tiles/v3/5/8/13.pbf"
    "tiles/v3/5/9/11.pbf"
    "tiles/v3/5/7/12.pbf"
    "tiles/v3/5/8/11.pbf"
    "tiles/v3/5/7/13.pbf"
    "tiles/v3/5/7/11.pbf"

    # greater la
    "tiles/v3/9/88/204.pbf"
    "tiles/v3/9/88/205.pbf"
    "tiles/v3/9/89/204.pbf"
    "tiles/v3/9/89/205.pbf"
    "tiles/v3/9/87/204.pbf"
    "tiles/v3/9/88/203.pbf"
    "tiles/v3/9/87/205.pbf"
    "tiles/v3/9/89/203.pbf"
    "tiles/v3/9/87/203.pbf"

    # sf
    "tiles/v3/14/2621/6333.pbf"
    "tiles/v3/14/2620/6333.pbf"
    "tiles/v3/14/2621/6334.pbf"
    "tiles/v3/14/2620/6334.pbf"
    "tiles/v3/14/2621/6332.pbf"
    "tiles/v3/14/2619/6333.pbf"
    "tiles/v3/14/2620/6332.pbf"
    "tiles/v3/14/2619/6334.pbf"
    "tiles/v3/14/2619/6332.pbf"

    # oakland
    "tiles/v3/12/657/1582.pbf"
    "tiles/v3/12/657/1583.pbf"
    "tiles/v3/12/658/1582.pbf"
    "tiles/v3/12/658/1583.pbf"
    "tiles/v3/12/656/1582.pbf"
    "tiles/v3/12/657/1581.pbf"
    "tiles/v3/12/656/1583.pbf"
    "tiles/v3/12/658/1581.pbf"
    "tiles/v3/12/656/1581.pbf"

    # germany
    "tiles/v3/6/34/20.pbf"
    "tiles/v3/6/33/20.pbf"
    "tiles/v3/6/32/20.pbf"

    # observed from dynamic benchmark
    "tiles/v3/0/0/0.pbf"
    "tiles/v3/1/0/0.pbf"
    "tiles/v3/1/0/1.pbf"
    "tiles/v3/1/1/0.pbf"
    "tiles/v3/1/1/1.pbf"
    "tiles/v3/2/0/0.pbf"
    "tiles/v3/2/0/1.pbf"
    "tiles/v3/2/0/2.pbf"
    "tiles/v3/2/0/3.pbf"
    "tiles/v3/2/1/0.pbf"
    "tiles/v3/2/1/1.pbf"
    "tiles/v3/2/1/2.pbf"
    "tiles/v3/2/1/3.pbf"
    "tiles/v3/2/2/0.pbf"
    "tiles/v3/2/2/1.pbf"
    "tiles/v3/2/2/2.pbf"
    "tiles/v3/2/3/0.pbf"
    "tiles/v3/2/3/1.pbf"
    "tiles/v3/2/3/2.pbf"
    "tiles/v3/3/0/2.pbf"
    "tiles/v3/3/0/3.pbf"
    "tiles/v3/3/0/4.pbf"
    "tiles/v3/3/1/2.pbf"
    "tiles/v3/3/1/3.pbf"
    "tiles/v3/3/1/4.pbf"
    "tiles/v3/3/1/5.pbf"
    "tiles/v3/3/2/1.pbf"
    "tiles/v3/3/2/2.pbf"
    "tiles/v3/3/2/3.pbf"
    "tiles/v3/3/2/4.pbf"
    "tiles/v3/3/2/5.pbf"
    "tiles/v3/3/3/1.pbf"
    "tiles/v3/3/3/2.pbf"
    "tiles/v3/3/3/3.pbf"
    "tiles/v3/3/3/4.pbf"
    "tiles/v3/3/3/5.pbf"
    "tiles/v3/3/4/1.pbf"
    "tiles/v3/3/4/2.pbf"
    "tiles/v3/3/4/3.pbf"
    "tiles/v3/3/4/4.pbf"
    "tiles/v3/3/5/1.pbf"
    "tiles/v3/3/5/2.pbf"
    "tiles/v3/3/5/3.pbf"
    "tiles/v3/3/5/4.pbf"
    "tiles/v3/3/6/2.pbf"
    "tiles/v3/3/6/3.pbf"
    "tiles/v3/3/6/4.pbf"
    "tiles/v3/3/7/2.pbf"
    "tiles/v3/3/7/3.pbf"
    "tiles/v3/3/7/4.pbf"
    "tiles/v3/4/1/5.pbf"
    "tiles/v3/4/1/6.pbf"
    "tiles/v3/4/1/7.pbf"
    "tiles/v3/4/10/6.pbf"
    "tiles/v3/4/10/7.pbf"
    "tiles/v3/4/10/8.pbf"
    "tiles/v3/4/11/6.pbf"
    "tiles/v3/4/11/7.pbf"
    "tiles/v3/4/11/8.pbf"
    "tiles/v3/4/12/5.pbf"
    "tiles/v3/4/12/6.pbf"
    "tiles/v3/4/12/7.pbf"
    "tiles/v3/4/12/8.pbf"
    "tiles/v3/4/13/5.pbf"
    "tiles/v3/4/13/6.pbf"
    "tiles/v3/4/13/7.pbf"
    "tiles/v3/4/14/5.pbf"
    "tiles/v3/4/14/6.pbf"
    "tiles/v3/4/14/7.pbf"
    "tiles/v3/4/2/5.pbf"
    "tiles/v3/4/2/6.pbf"
    "tiles/v3/4/2/7.pbf"
    "tiles/v3/4/3/5.pbf"
    "tiles/v3/4/3/6.pbf"
    "tiles/v3/4/3/7.pbf"
    "tiles/v3/4/3/8.pbf"
    "tiles/v3/4/3/9.pbf"
    "tiles/v3/4/4/5.pbf"
    "tiles/v3/4/4/6.pbf"
    "tiles/v3/4/4/7.pbf"
    "tiles/v3/4/4/8.pbf"
    "tiles/v3/4/4/9.pbf"
    "tiles/v3/4/5/5.pbf"
    "tiles/v3/4/5/6.pbf"
    "tiles/v3/4/5/7.pbf"
    "tiles/v3/4/5/8.pbf"
    "tiles/v3/4/5/9.pbf"
    "tiles/v3/4/6/4.pbf"
    "tiles/v3/4/6/5.pbf"
    "tiles/v3/4/6/6.pbf"
    "tiles/v3/4/6/7.pbf"
    "tiles/v3/4/6/8.pbf"
    "tiles/v3/4/7/4.pbf"
    "tiles/v3/4/7/5.pbf"
    "tiles/v3/4/7/6.pbf"
    "tiles/v3/4/8/3.pbf"
    "tiles/v3/4/8/4.pbf"
    "tiles/v3/4/8/5.pbf"
    "tiles/v3/4/8/6.pbf"
    "tiles/v3/4/9/3.pbf"
    "tiles/v3/4/9/4.pbf"
    "tiles/v3/4/9/5.pbf"
    "tiles/v3/4/9/6.pbf"
    "tiles/v3/5/10/15.pbf"
    "tiles/v3/5/10/16.pbf"
    "tiles/v3/5/10/17.pbf"
    "tiles/v3/5/10/18.pbf"
    "tiles/v3/5/15/10.pbf"
    "tiles/v3/5/15/11.pbf"
    "tiles/v3/5/15/9.pbf"
    "tiles/v3/5/16/10.pbf"
    "tiles/v3/5/16/11.pbf"
    "tiles/v3/5/16/9.pbf"
    "tiles/v3/5/17/10.pbf"
    "tiles/v3/5/17/11.pbf"
    "tiles/v3/5/17/8.pbf"
    "tiles/v3/5/17/9.pbf"
    "tiles/v3/5/18/10.pbf"
    "tiles/v3/5/18/8.pbf"
    "tiles/v3/5/18/9.pbf"
    "tiles/v3/5/21/13.pbf"
    "tiles/v3/5/21/14.pbf"
    "tiles/v3/5/21/15.pbf"
    "tiles/v3/5/22/13.pbf"
    "tiles/v3/5/22/14.pbf"
    "tiles/v3/5/22/15.pbf"
    "tiles/v3/5/23/13.pbf"
    "tiles/v3/5/23/14.pbf"
    "tiles/v3/5/23/15.pbf"
    "tiles/v3/5/25/12.pbf"
    "tiles/v3/5/25/13.pbf"
    "tiles/v3/5/25/14.pbf"
    "tiles/v3/5/26/12.pbf"
    "tiles/v3/5/26/13.pbf"
    "tiles/v3/5/26/14.pbf"
    "tiles/v3/5/27/12.pbf"
    "tiles/v3/5/27/13.pbf"
    "tiles/v3/5/27/14.pbf"
    "tiles/v3/5/4/11.pbf"
    "tiles/v3/5/4/12.pbf"
    "tiles/v3/5/4/13.pbf"
    "tiles/v3/5/5/11.pbf"
    "tiles/v3/5/5/12.pbf"
    "tiles/v3/5/5/13.pbf"
    "tiles/v3/5/8/15.pbf"
    "tiles/v3/5/8/16.pbf"
    "tiles/v3/5/8/17.pbf"
    "tiles/v3/5/8/18.pbf"
    "tiles/v3/5/9/15.pbf"
    "tiles/v3/5/9/16.pbf"
    "tiles/v3/5/9/17.pbf"
    "tiles/v3/5/9/18.pbf"
    "tiles/v3/6/10/23.pbf"
    "tiles/v3/6/10/24.pbf"
    "tiles/v3/6/10/25.pbf"
    "tiles/v3/6/17/23.pbf"
    "tiles/v3/6/17/24.pbf"
    "tiles/v3/6/17/25.pbf"
    "tiles/v3/6/18/23.pbf"
    "tiles/v3/6/18/24.pbf"
    "tiles/v3/6/18/25.pbf"
    "tiles/v3/6/18/33.pbf"
    "tiles/v3/6/18/34.pbf"
    "tiles/v3/6/18/35.pbf"
    "tiles/v3/6/19/23.pbf"
    "tiles/v3/6/19/24.pbf"
    "tiles/v3/6/19/25.pbf"
    "tiles/v3/6/19/33.pbf"
    "tiles/v3/6/19/34.pbf"
    "tiles/v3/6/19/35.pbf"
    "tiles/v3/6/33/19.pbf"
    "tiles/v3/6/34/19.pbf"
    "tiles/v3/6/35/17.pbf"
    "tiles/v3/6/35/18.pbf"
    "tiles/v3/6/35/19.pbf"
    "tiles/v3/6/35/20.pbf"
    "tiles/v3/6/35/21.pbf"
    "tiles/v3/6/35/22.pbf"
    "tiles/v3/6/36/17.pbf"
    "tiles/v3/6/36/18.pbf"
    "tiles/v3/6/36/19.pbf"
    "tiles/v3/6/37/17.pbf"
    "tiles/v3/6/37/18.pbf"
    "tiles/v3/6/37/19.pbf"
    "tiles/v3/6/44/28.pbf"
    "tiles/v3/6/44/29.pbf"
    "tiles/v3/6/44/30.pbf"
    "tiles/v3/6/45/28.pbf"
    "tiles/v3/6/45/29.pbf"
    "tiles/v3/6/45/30.pbf"
    "tiles/v3/6/46/28.pbf"
    "tiles/v3/6/46/29.pbf"
    "tiles/v3/6/46/30.pbf"
    "tiles/v3/6/52/25.pbf"
    "tiles/v3/6/52/26.pbf"
    "tiles/v3/6/52/27.pbf"
    "tiles/v3/6/53/25.pbf"
    "tiles/v3/6/53/26.pbf"
    "tiles/v3/6/53/27.pbf"
    "tiles/v3/6/54/25.pbf"
    "tiles/v3/6/54/26.pbf"
    "tiles/v3/6/54/27.pbf"
    "tiles/v3/6/9/23.pbf"
    "tiles/v3/6/9/24.pbf"
    "tiles/v3/6/9/25.pbf"
    "tiles/v3/7/106/51.pbf"
    "tiles/v3/7/106/52.pbf"
    "tiles/v3/7/106/53.pbf"
    "tiles/v3/7/107/51.pbf"
    "tiles/v3/7/107/52.pbf"
    "tiles/v3/7/107/53.pbf"
    "tiles/v3/7/19/48.pbf"
    "tiles/v3/7/19/49.pbf"
    "tiles/v3/7/19/50.pbf"
    "tiles/v3/7/20/48.pbf"
    "tiles/v3/7/20/49.pbf"
    "tiles/v3/7/20/50.pbf"
    "tiles/v3/7/21/48.pbf"
    "tiles/v3/7/21/49.pbf"
    "tiles/v3/7/21/50.pbf"
    "tiles/v3/7/35/47.pbf"
    "tiles/v3/7/35/48.pbf"
    "tiles/v3/7/35/49.pbf"
    "tiles/v3/7/36/47.pbf"
    "tiles/v3/7/36/48.pbf"
    "tiles/v3/7/36/49.pbf"
    "tiles/v3/7/36/67.pbf"
    "tiles/v3/7/36/68.pbf"
    "tiles/v3/7/36/69.pbf"
    "tiles/v3/7/37/47.pbf"
    "tiles/v3/7/37/48.pbf"
    "tiles/v3/7/37/49.pbf"
    "tiles/v3/7/37/67.pbf"
    "tiles/v3/7/37/68.pbf"
    "tiles/v3/7/37/69.pbf"
    "tiles/v3/7/38/67.pbf"
    "tiles/v3/7/38/68.pbf"
    "tiles/v3/7/38/69.pbf"
    "tiles/v3/7/64/41.pbf"
    "tiles/v3/7/64/42.pbf"
    "tiles/v3/7/64/43.pbf"
    "tiles/v3/7/65/41.pbf"
    "tiles/v3/7/65/42.pbf"
    "tiles/v3/7/65/43.pbf"
    "tiles/v3/7/66/41.pbf"
    "tiles/v3/7/66/42.pbf"
    "tiles/v3/7/66/43.pbf"
    "tiles/v3/7/67/41.pbf"
    "tiles/v3/7/67/42.pbf"
    "tiles/v3/7/67/43.pbf"
    "tiles/v3/7/68/40.pbf"
    "tiles/v3/7/68/41.pbf"
    "tiles/v3/7/68/42.pbf"
    "tiles/v3/7/68/43.pbf"
    "tiles/v3/7/69/40.pbf"
    "tiles/v3/7/69/41.pbf"
    "tiles/v3/7/69/42.pbf"
    "tiles/v3/7/69/43.pbf"
    "tiles/v3/7/72/36.pbf"
    "tiles/v3/7/72/37.pbf"
    "tiles/v3/7/72/38.pbf"
    "tiles/v3/7/73/36.pbf"
    "tiles/v3/7/73/37.pbf"
    "tiles/v3/7/73/38.pbf"
    "tiles/v3/7/90/58.pbf"
    "tiles/v3/7/90/59.pbf"
    "tiles/v3/7/90/60.pbf"
    "tiles/v3/7/91/58.pbf"
    "tiles/v3/7/91/59.pbf"
    "tiles/v3/7/91/60.pbf"
    "tiles/v3/7/92/58.pbf"
    "tiles/v3/7/92/59.pbf"
    "tiles/v3/7/92/60.pbf"
    "tiles/v3/8/130/83.pbf"
    "tiles/v3/8/130/84.pbf"
    "tiles/v3/8/130/85.pbf"
    "tiles/v3/8/131/83.pbf"
    "tiles/v3/8/131/84.pbf"
    "tiles/v3/8/131/85.pbf"
    "tiles/v3/8/132/83.pbf"
    "tiles/v3/8/132/84.pbf"
    "tiles/v3/8/132/85.pbf"
    "tiles/v3/8/136/82.pbf"
    "tiles/v3/8/136/83.pbf"
    "tiles/v3/8/136/84.pbf"
    "tiles/v3/8/137/82.pbf"
    "tiles/v3/8/137/83.pbf"
    "tiles/v3/8/137/84.pbf"
    "tiles/v3/8/138/82.pbf"
    "tiles/v3/8/138/83.pbf"
    "tiles/v3/8/138/84.pbf"
    "tiles/v3/8/144/73.pbf"
    "tiles/v3/8/144/74.pbf"
    "tiles/v3/8/144/75.pbf"
    "tiles/v3/8/145/73.pbf"
    "tiles/v3/8/145/74.pbf"
    "tiles/v3/8/145/75.pbf"
    "tiles/v3/8/146/73.pbf"
    "tiles/v3/8/146/74.pbf"
    "tiles/v3/8/146/75.pbf"
    "tiles/v3/8/182/117.pbf"
    "tiles/v3/8/182/118.pbf"
    "tiles/v3/8/182/119.pbf"
    "tiles/v3/8/183/117.pbf"
    "tiles/v3/8/183/118.pbf"
    "tiles/v3/8/183/119.pbf"
    "tiles/v3/8/213/103.pbf"
    "tiles/v3/8/213/104.pbf"
    "tiles/v3/8/213/105.pbf"
    "tiles/v3/8/214/103.pbf"
    "tiles/v3/8/214/104.pbf"
    "tiles/v3/8/214/105.pbf"
    "tiles/v3/8/215/103.pbf"
    "tiles/v3/8/215/104.pbf"
    "tiles/v3/8/215/105.pbf"
    "tiles/v3/8/40/97.pbf"
    "tiles/v3/8/40/98.pbf"
    "tiles/v3/8/40/99.pbf"
    "tiles/v3/8/41/97.pbf"
    "tiles/v3/8/41/98.pbf"
    "tiles/v3/8/41/99.pbf"
    "tiles/v3/8/72/96.pbf"
    "tiles/v3/8/72/97.pbf"
    "tiles/v3/8/72/98.pbf"
    "tiles/v3/8/73/96.pbf"
    "tiles/v3/8/73/97.pbf"
    "tiles/v3/8/73/98.pbf"
    "tiles/v3/8/74/136.pbf"
    "tiles/v3/8/74/137.pbf"
    "tiles/v3/8/74/138.pbf"
    "tiles/v3/8/75/136.pbf"
    "tiles/v3/8/75/137.pbf"
    "tiles/v3/8/75/138.pbf"
    "tiles/v3/9/145/194.pbf"
    "tiles/v3/9/145/195.pbf"
    "tiles/v3/9/145/196.pbf"
    "tiles/v3/9/146/194.pbf"
    "tiles/v3/9/146/195.pbf"
    "tiles/v3/9/146/196.pbf"
    "tiles/v3/9/147/194.pbf"
    "tiles/v3/9/147/195.pbf"
    "tiles/v3/9/147/196.pbf"
    "tiles/v3/9/149/273.pbf"
    "tiles/v3/9/149/274.pbf"
    "tiles/v3/9/149/275.pbf"
    "tiles/v3/9/150/273.pbf"
    "tiles/v3/9/150/274.pbf"
    "tiles/v3/9/150/275.pbf"
    "tiles/v3/9/151/273.pbf"
    "tiles/v3/9/151/274.pbf"
    "tiles/v3/9/151/275.pbf"
    "tiles/v3/9/262/167.pbf"
    "tiles/v3/9/262/168.pbf"
    "tiles/v3/9/262/169.pbf"
    "tiles/v3/9/263/167.pbf"
    "tiles/v3/9/263/168.pbf"
    "tiles/v3/9/263/169.pbf"
    "tiles/v3/9/274/166.pbf"
    "tiles/v3/9/274/167.pbf"
    "tiles/v3/9/274/168.pbf"
    "tiles/v3/9/275/166.pbf"
    "tiles/v3/9/275/167.pbf"
    "tiles/v3/9/275/168.pbf"
    "tiles/v3/9/290/147.pbf"
    "tiles/v3/9/290/148.pbf"
    "tiles/v3/9/290/149.pbf"
    "tiles/v3/9/291/147.pbf"
    "tiles/v3/9/291/148.pbf"
    "tiles/v3/9/291/149.pbf"
    "tiles/v3/9/292/147.pbf"
    "tiles/v3/9/292/148.pbf"
    "tiles/v3/9/292/149.pbf"
    "tiles/v3/9/365/236.pbf"
    "tiles/v3/9/365/237.pbf"
    "tiles/v3/9/365/238.pbf"
    "tiles/v3/9/366/236.pbf"
    "tiles/v3/9/366/237.pbf"
    "tiles/v3/9/366/238.pbf"
    "tiles/v3/9/367/236.pbf"
    "tiles/v3/9/367/237.pbf"
    "tiles/v3/9/367/238.pbf"
    "tiles/v3/9/428/208.pbf"
    "tiles/v3/9/428/209.pbf"
    "tiles/v3/9/428/210.pbf"
    "tiles/v3/9/429/208.pbf"
    "tiles/v3/9/429/209.pbf"
    "tiles/v3/9/429/210.pbf"
    "tiles/v3/9/81/196.pbf"
    "tiles/v3/9/81/197.pbf"
    "tiles/v3/9/81/198.pbf"
    "tiles/v3/9/82/196.pbf"
    "tiles/v3/9/82/197.pbf"
    "tiles/v3/9/82/198.pbf"
    "tiles/v3/10/163/394.pbf"
    "tiles/v3/10/163/395.pbf"
    "tiles/v3/10/163/396.pbf"
    "tiles/v3/10/164/394.pbf"
    "tiles/v3/10/164/395.pbf"
    "tiles/v3/10/164/396.pbf"
    "tiles/v3/10/292/390.pbf"
    "tiles/v3/10/292/391.pbf"
    "tiles/v3/10/292/392.pbf"
    "tiles/v3/10/293/390.pbf"
    "tiles/v3/10/293/391.pbf"
    "tiles/v3/10/293/392.pbf"
    "tiles/v3/10/300/548.pbf"
    "tiles/v3/10/300/549.pbf"
    "tiles/v3/10/300/550.pbf"
    "tiles/v3/10/301/548.pbf"
    "tiles/v3/10/301/549.pbf"
    "tiles/v3/10/301/550.pbf"
    "tiles/v3/10/525/335.pbf"
    "tiles/v3/10/525/336.pbf"
    "tiles/v3/10/525/337.pbf"
    "tiles/v3/10/526/335.pbf"
    "tiles/v3/10/526/336.pbf"
    "tiles/v3/10/526/337.pbf"
    "tiles/v3/10/549/334.pbf"
    "tiles/v3/10/549/335.pbf"
    "tiles/v3/10/549/336.pbf"
    "tiles/v3/10/550/334.pbf"
    "tiles/v3/10/550/335.pbf"
    "tiles/v3/10/550/336.pbf"
    "tiles/v3/10/582/295.pbf"
    "tiles/v3/10/582/296.pbf"
    "tiles/v3/10/582/297.pbf"
    "tiles/v3/10/583/295.pbf"
    "tiles/v3/10/583/296.pbf"
    "tiles/v3/10/583/297.pbf"
    "tiles/v3/10/731/473.pbf"
    "tiles/v3/10/731/474.pbf"
    "tiles/v3/10/731/475.pbf"
    "tiles/v3/10/732/473.pbf"
    "tiles/v3/10/732/474.pbf"
    "tiles/v3/10/732/475.pbf"
    "tiles/v3/10/733/473.pbf"
    "tiles/v3/10/733/474.pbf"
    "tiles/v3/10/733/475.pbf"
    "tiles/v3/10/856/417.pbf"
    "tiles/v3/10/856/418.pbf"
    "tiles/v3/10/856/419.pbf"
    "tiles/v3/10/857/417.pbf"
    "tiles/v3/10/857/418.pbf"
    "tiles/v3/10/857/419.pbf"
    "tiles/v3/10/858/417.pbf"
    "tiles/v3/10/858/418.pbf"
    "tiles/v3/10/858/419.pbf"
    "tiles/v3/11/1051/672.pbf"
    "tiles/v3/11/1051/673.pbf"
    "tiles/v3/11/1051/674.pbf"
    "tiles/v3/11/1052/672.pbf"
    "tiles/v3/11/1052/673.pbf"
    "tiles/v3/11/1052/674.pbf"
    "tiles/v3/11/1099/670.pbf"
    "tiles/v3/11/1099/671.pbf"
    "tiles/v3/11/1099/672.pbf"
    "tiles/v3/11/1100/670.pbf"
    "tiles/v3/11/1100/671.pbf"
    "tiles/v3/11/1100/672.pbf"
    "tiles/v3/11/1101/670.pbf"
    "tiles/v3/11/1101/671.pbf"
    "tiles/v3/11/1101/672.pbf"
    "tiles/v3/11/1165/591.pbf"
    "tiles/v3/11/1165/592.pbf"
    "tiles/v3/11/1165/593.pbf"
    "tiles/v3/11/1166/591.pbf"
    "tiles/v3/11/1166/592.pbf"
    "tiles/v3/11/1166/593.pbf"
    "tiles/v3/11/1464/948.pbf"
    "tiles/v3/11/1464/949.pbf"
    "tiles/v3/11/1464/950.pbf"
    "tiles/v3/11/1465/948.pbf"
    "tiles/v3/11/1465/949.pbf"
    "tiles/v3/11/1465/950.pbf"
    "tiles/v3/11/1466/948.pbf"
    "tiles/v3/11/1466/949.pbf"
    "tiles/v3/11/1466/950.pbf"
    "tiles/v3/11/1714/835.pbf"
    "tiles/v3/11/1714/836.pbf"
    "tiles/v3/11/1714/837.pbf"
    "tiles/v3/11/1715/835.pbf"
    "tiles/v3/11/1715/836.pbf"
    "tiles/v3/11/1715/837.pbf"
    "tiles/v3/11/326/790.pbf"
    "tiles/v3/11/326/791.pbf"
    "tiles/v3/11/326/792.pbf"
    "tiles/v3/11/327/790.pbf"
    "tiles/v3/11/327/791.pbf"
    "tiles/v3/11/327/792.pbf"
    "tiles/v3/11/328/790.pbf"
    "tiles/v3/11/328/791.pbf"
    "tiles/v3/11/328/792.pbf"
    "tiles/v3/11/585/782.pbf"
    "tiles/v3/11/585/783.pbf"
    "tiles/v3/11/585/784.pbf"
    "tiles/v3/11/584/782.pbf"
    "tiles/v3/11/584/783.pbf"
    "tiles/v3/11/584/784.pbf"
    "tiles/v3/11/586/782.pbf"
    "tiles/v3/11/586/783.pbf"
    "tiles/v3/11/586/784.pbf"
    "tiles/v3/11/601/1098.pbf"
    "tiles/v3/11/601/1099.pbf"
    "tiles/v3/11/601/1100.pbf"
    "tiles/v3/11/602/1098.pbf"
    "tiles/v3/11/602/1099.pbf"
    "tiles/v3/11/602/1100.pbf"
    "tiles/v3/12/1170/1565.pbf"
    "tiles/v3/12/1170/1566.pbf"
    "tiles/v3/12/1170/1567.pbf"
    "tiles/v3/12/1171/1565.pbf"
    "tiles/v3/12/1171/1566.pbf"
    "tiles/v3/12/1171/1567.pbf"
    "tiles/v3/12/1172/1565.pbf"
    "tiles/v3/12/1172/1566.pbf"
    "tiles/v3/12/1172/1567.pbf"
    "tiles/v3/12/1202/2198.pbf"
    "tiles/v3/12/1202/2199.pbf"
    "tiles/v3/12/1202/2200.pbf"
    "tiles/v3/12/1203/2198.pbf"
    "tiles/v3/12/1203/2199.pbf"
    "tiles/v3/12/1203/2200.pbf"
    "tiles/v3/12/1204/2198.pbf"
    "tiles/v3/12/1204/2199.pbf"
    "tiles/v3/12/1204/2200.pbf"
    "tiles/v3/12/2102/1345.pbf"
    "tiles/v3/12/2102/1346.pbf"
    "tiles/v3/12/2102/1347.pbf"
    "tiles/v3/12/2103/1345.pbf"
    "tiles/v3/12/2103/1346.pbf"
    "tiles/v3/12/2103/1347.pbf"
    "tiles/v3/12/2104/1345.pbf"
    "tiles/v3/12/2104/1346.pbf"
    "tiles/v3/12/2104/1347.pbf"
    "tiles/v3/12/2199/1342.pbf"
    "tiles/v3/12/2199/1343.pbf"
    "tiles/v3/12/2199/1344.pbf"
    "tiles/v3/12/2200/1342.pbf"
    "tiles/v3/12/2200/1343.pbf"
    "tiles/v3/12/2200/1344.pbf"
    "tiles/v3/12/2201/1342.pbf"
    "tiles/v3/12/2201/1343.pbf"
    "tiles/v3/12/2201/1344.pbf"
    "tiles/v3/12/2330/1184.pbf"
    "tiles/v3/12/2330/1185.pbf"
    "tiles/v3/12/2330/1186.pbf"
    "tiles/v3/12/2331/1184.pbf"
    "tiles/v3/12/2331/1185.pbf"
    "tiles/v3/12/2331/1186.pbf"
    "tiles/v3/12/2332/1184.pbf"
    "tiles/v3/12/2332/1185.pbf"
    "tiles/v3/12/2332/1186.pbf"
    "tiles/v3/12/2930/1898.pbf"
    "tiles/v3/12/2930/1899.pbf"
    "tiles/v3/12/2930/1900.pbf"
    "tiles/v3/12/2931/1898.pbf"
    "tiles/v3/12/2931/1899.pbf"
    "tiles/v3/12/2931/1900.pbf"
    "tiles/v3/12/3429/1672.pbf"
    "tiles/v3/12/3429/1673.pbf"
    "tiles/v3/12/3429/1674.pbf"
    "tiles/v3/12/3430/1672.pbf"
    "tiles/v3/12/3430/1673.pbf"
    "tiles/v3/12/3430/1674.pbf"
    "tiles/v3/12/654/1582.pbf"
    "tiles/v3/12/654/1583.pbf"
    "tiles/v3/12/654/1584.pbf"
    "tiles/v3/12/655/1582.pbf"
    "tiles/v3/12/655/1583.pbf"
    "tiles/v3/12/655/1584.pbf"
    "tiles/v3/13/1309/3165.pbf"
    "tiles/v3/13/1309/3166.pbf"
    "tiles/v3/13/1309/3167.pbf"
    "tiles/v3/13/1310/3165.pbf"
    "tiles/v3/13/1310/3166.pbf"
    "tiles/v3/13/1310/3167.pbf"
    "tiles/v3/13/1311/3165.pbf"
    "tiles/v3/13/1311/3166.pbf"
    "tiles/v3/13/1311/3167.pbf"
    "tiles/v3/13/2342/3132.pbf"
    "tiles/v3/13/2342/3133.pbf"
    "tiles/v3/13/2342/3134.pbf"
    "tiles/v3/13/2343/3132.pbf"
    "tiles/v3/13/2343/3133.pbf"
    "tiles/v3/13/2343/3134.pbf"
    "tiles/v3/13/2406/4397.pbf"
    "tiles/v3/13/2406/4398.pbf"
    "tiles/v3/13/2406/4399.pbf"
    "tiles/v3/13/2407/4397.pbf"
    "tiles/v3/13/2407/4398.pbf"
    "tiles/v3/13/2407/4399.pbf"
    "tiles/v3/13/4206/2691.pbf"
    "tiles/v3/13/4206/2692.pbf"
    "tiles/v3/13/4206/2693.pbf"
    "tiles/v3/13/4207/2691.pbf"
    "tiles/v3/13/4207/2692.pbf"
    "tiles/v3/13/4207/2693.pbf"
    "tiles/v3/13/4208/2691.pbf"
    "tiles/v3/13/4208/2692.pbf"
    "tiles/v3/13/4208/2693.pbf"
    "tiles/v3/13/4400/2685.pbf"
    "tiles/v3/13/4400/2686.pbf"
    "tiles/v3/13/4400/2687.pbf"
    "tiles/v3/13/4401/2685.pbf"
    "tiles/v3/13/4401/2686.pbf"
    "tiles/v3/13/4401/2687.pbf"
    "tiles/v3/13/4662/2370.pbf"
    "tiles/v3/13/4662/2371.pbf"
    "tiles/v3/13/4662/2372.pbf"
    "tiles/v3/13/4663/2370.pbf"
    "tiles/v3/13/4663/2371.pbf"
    "tiles/v3/13/4663/2372.pbf"
    "tiles/v3/13/4664/2370.pbf"
    "tiles/v3/13/4664/2371.pbf"
    "tiles/v3/13/4664/2372.pbf"
    "tiles/v3/13/5860/3797.pbf"
    "tiles/v3/13/5860/3798.pbf"
    "tiles/v3/13/5860/3799.pbf"
    "tiles/v3/13/5861/3797.pbf"
    "tiles/v3/13/5861/3798.pbf"
    "tiles/v3/13/5861/3799.pbf"
    "tiles/v3/13/5862/3797.pbf"
    "tiles/v3/13/5862/3798.pbf"
    "tiles/v3/13/5862/3799.pbf"
    "tiles/v3/13/6859/3346.pbf"
    "tiles/v3/13/6859/3347.pbf"
    "tiles/v3/13/6859/3348.pbf"
    "tiles/v3/13/6860/3346.pbf"
    "tiles/v3/13/6860/3347.pbf"
    "tiles/v3/13/6860/3348.pbf"
    "tiles/v3/14/2619/6331.pbf"
    "tiles/v3/14/2620/6331.pbf"
    "tiles/v3/14/2621/6331.pbf"
    "tiles/v3/14/4685/6266.pbf"
    "tiles/v3/14/4685/6267.pbf"
    "tiles/v3/14/4685/6268.pbf"
    "tiles/v3/14/4686/6266.pbf"
    "tiles/v3/14/4686/6267.pbf"
    "tiles/v3/14/4686/6268.pbf"
    "tiles/v3/14/4813/8795.pbf"
    "tiles/v3/14/4813/8796.pbf"
    "tiles/v3/14/4813/8797.pbf"
    "tiles/v3/14/4814/8795.pbf"
    "tiles/v3/14/4814/8796.pbf"
    "tiles/v3/14/4814/8797.pbf"
    "tiles/v3/14/8414/5383.pbf"
    "tiles/v3/14/8414/5384.pbf"
    "tiles/v3/14/8414/5385.pbf"
    "tiles/v3/14/8415/5383.pbf"
    "tiles/v3/14/8415/5384.pbf"
    "tiles/v3/14/8415/5385.pbf"
    "tiles/v3/14/8801/5372.pbf"
    "tiles/v3/14/8801/5373.pbf"
    "tiles/v3/14/8801/5374.pbf"
    "tiles/v3/14/8802/5372.pbf"
    "tiles/v3/14/8802/5373.pbf"
    "tiles/v3/14/8802/5374.pbf"
    "tiles/v3/14/9326/4741.pbf"
    "tiles/v3/14/9326/4742.pbf"
    "tiles/v3/14/9326/4743.pbf"
    "tiles/v3/14/9327/4741.pbf"
    "tiles/v3/14/9327/4742.pbf"
    "tiles/v3/14/9327/4743.pbf"
    "tiles/v3/14/11722/7595.pbf"
    "tiles/v3/14/11722/7596.pbf"
    "tiles/v3/14/11722/7597.pbf"
    "tiles/v3/14/11723/7595.pbf"
    "tiles/v3/14/11723/7596.pbf"
    "tiles/v3/14/11723/7597.pbf"
    "tiles/v3/14/11724/7595.pbf"
    "tiles/v3/14/11724/7596.pbf"
    "tiles/v3/14/11724/7597.pbf"
    "tiles/v3/14/13719/6693.pbf"
    "tiles/v3/14/13719/6694.pbf"
    "tiles/v3/14/13719/6695.pbf"
    "tiles/v3/14/13720/6693.pbf"
    "tiles/v3/14/13720/6694.pbf"
    "tiles/v3/14/13720/6695.pbf"
    "tiles/v3/14/13721/6693.pbf"
    "tiles/v3/14/13721/6694.pbf"
    "tiles/v3/14/13721/6695.pbf"
)

for OUTPUT in ${LIST[@]} ; do
    if [ ! -f "${OUTPUT}" ] ; then
        mkdir -p "`dirname "${OUTPUT}"`"
        echo "Downloading tile '${OUTPUT}'"
        echo "https://api.maptiler.com/${OUTPUT}?key=${MH_API_KEY}"
        curl -H "Accept-Encoding: gzip" -# "https://api.maptiler.com/${OUTPUT}?key=${MH_API_KEY}" | gunzip > "${OUTPUT}"
    fi
done
