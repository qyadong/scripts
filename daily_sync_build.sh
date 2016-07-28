#!/bin/bash

export LAST_COMMIT_FILE=lastcommit.log
export CUR_COMMIT_FILE=currentcommit.log

export DAILY_PATH=/disk2/projects/daily_build

export now=`date +%Y%m%d-%H%M%S`
mkdir $DAILY_PATH/$now
export build_dir=$DAILY_PATH/$now
export output_dir=$build_dir
export pub_dir=$build_dir
mkdir $output_dir/$now

if [ -f "$DAILY_PATH/record.log" ]; then
	echo "record.log already exists!"
else
	touch $DAILY_PATH/record.log
fi

echo $now >> $DAILY_PATH/record.log

#get code
get_code() {
cd $build_dir

echo "init manifests"
/home/yadong/bin/repo init -u ssh://android.intel.com/manifests -b android/master -m r0
echo "sync code for all repo projects.."
/home/yadong/bin/repo sync -j5

echo $now >> $DAILY_PATH/record.log

echo " get code done."

}

#build Trusty/LK
build_trusty(){
croot
cd trusty
croot
}

#build evmm
build_tos(){
source build/envsetup.sh

croot
cd vendor/intel/fw/evmm/
make
cp ../../../../trusty/build-trail-x86-64/lk.bin loader/pre_os/build/linux/release/
make
cp bin/linux/release/ikgt_pkg.bin ../../../../prebuilts/misc/evmm_pkg.bin
croot

#croot
#make tosimg

}

#build android kernel
#build_android_kernel(){

#}

#copy image
copy_image(){
croot

}

#build_gsd
build_gsd(){

source build/envsetup.sh
rm $build_dir/vendor/intel/fw/evmm/prebuilts/*
lunch gsd_simics-userdebug
make gptimage -j8 2>&1 |tee build_gsd.log

# package the ipc-unit test
mmm system/core/trusty/libtrusty
mmm system/core/trusty/libtrusty/tipc-test

croot
make gptimage -j8 2>&1 |tee build_gsd_tipc.log
}

#build bxt-p
build_bxtp_abl(){

source build/envsetup.sh
rm $build_dir/vendor/intel/fw/evmm/prebuilts/*

lunch lunch bxtp_abl-userdebug
make ABL_BUILD_FROM_SRC=true flashfiles -j8 2>&1 |tee build_bxtp_abl.log

mmm system/core/trusty/libtrusty
mmm system/core/trusty/libtrusty/tipc-test

croot
make ABL_BUILD_FROM_SRC=true flashfiles -j8 2>&1 |tee build_bxtp_abl_tipc.log
}

#copy_image_gsd
copy_image_gsd(){
cp -r $build_dir/out/target/product/gsd_simics/gsd_simics.img $pub_dir/$now/
}

#send mail
send_mail() {
email_body=$build_dir/email.log

 echo "sending mail..."
  if [ -f "$build_dir/out/target/product/gsd_simics/gsd_simics.img" ] ; then
      email_subject="1A Trusty Daily Build Successful"
      echo "Today's 1A Trusty Daily Build Successful! " >> $email_body
      echo "Image can be found here @ http://10.239.92.141/$build_dir/out  " >> $email_body
      echo "Please refer to doc https://docs.google.com/document/d/1-hqZ9qwe3fznhXTzu-NYiZOnwFQNK1LAxEDMTdrq-ag/edit?pli=1 for how to use the image" >>$email_body


  else
      email_subject="1A Trusty Daiy Build FAIL"
      echo "Today's 1A Trusty Daily Build FAILED!" >> $email_body
#      echo " Error messages as below:" >> $email_body
#	  cd $output_dir/$now
#   cat tr_error.log evmm_error.log a_k_error.log a_error.log >> $email_body
  fi
  #echo "Committed changes:"
  #cat $output_dir/$now/change.log >> $email_body

cat "$email_body"| mutt -s "$email_subject" yadong.qi@intel.com
echo "email send done!"

}

#clean old repo
clean_old(){

declare -i old_folder_num=`cat $DAILY_PATH/record.log |wc -l`
old_folder=`head -1 $DAILY_PATH/record.log`
if [ $old_folder_num -ge 3 ];then
	rm -rf $DAILY_PATH/$old_folder
	sed -i '1d' $DAILY_PATH/record.log
fi

}

cd $build_dir

get_code

build_gsd

build_bxtp_abl

clean_old

send_mail

