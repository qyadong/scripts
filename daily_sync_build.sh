#!/bin/bash

#
#Note: need to add link in /bin
#     1. sudo ln -s ~/bin/repo /bin/repo
#     2. sudo ln -s /sbin/mke2fs /bin/mke2fs
#

source /home/yadong/.bashrc

export LAST_COMMIT_FILE=lastcommit.log
export CUR_COMMIT_FILE=currentcommit.log

export DAILY_PATH=/ssd_disk2/daily_build

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

#get code
get_code() {
cd $build_dir

branch=$1
manifest=$2

echo "init manifests for branch:$branch , manifest:$manifest"
/home/yadong/bin/repo init -u ssh://android.intel.com/manifests -b $branch -m $manifest
echo "sync code for all repo projects.."
/home/yadong/bin/repo sync -c 2>&1 |tee sync_code.log

while grep -E "cannot initialize work tree|error: Exited sync due to fetch errors" ./sync_code.log ; do
	#delete corrupted .git/
	#for i in `grep -o "pack-[0-9a-zA-Z]\+\.pack$" ./sync_code.log`; do name=`find ./ -name $i |grep -o "[0-9a-zA-Z\\\/\.\_\-]\+\.git"` && echo $name && rm -rf $name; done

	for string in `grep "^fatal.*(.*)" ./sync_code.log |cut -d '.' -f2- |cut -d ')' -f1`
	do
		string=${string%)*}
		#echo $string

		while [[ $string =~ "/" ]]
		do
			string=${string#*/}
		done

		echo $string

		name=`find ./.repo/projects -name $string |grep -o "[0-9a-zA-Z\\\/\.\_\-]\+\.git"`

		if [[ $name != "" ]]; then
			echo "Delete corrupted git: $name"
			rm -rf $name
		fi

	done

	rm -rf $build_dir/*
	#/home/yadong/bin/repo forall -vc "git reset --hard"
	/home/yadong/bin/repo sync 2>&1  |tee sync_code.log
done

#/home/yadong/bin/repo forall -vc "git reset --hard"

#echo "update manifests..."
#cd .repo/manifests
#git pull origin android/master

#/home/yadong/bin/repo sync

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

#apply patch
apply_patch(){
prj_path=$1
prj_name=$2
patch_id=$3

cd $prj_path && git fetch ssh://yadongqi@android.intel.com:29418/$prj_name $patch_id && git cherry-pick FETCH_HEAD
cd -
}

#build bxt-p
build_bxtp_abl(){

cd $build_dir

#cd vendor/intel/abl/bootloader_apl && git reset --hard 8863d277a7e8c3cda57df8f5e02deb1281e9f831 && cd -
#cd system/core/trusty && git am /disk2/projects/daily_build/0001-Trusty-Add-result-check-on-tipc-test-cases.patch && cd -
#vendor/intel/utils/autopatch.py 522989 522985 520033 520429 510854 523435

# Trusty enable in mixin.spec
vendor/intel/utils/autopatch.py 544565
# [trusty] Build multiboot image in trusty mixin
#vendor/intel/utils/autopatch.py 544556
# Enable multiboot partition
vendor/intel/utils/autopatch.py 551133
# Booting the VMM
vendor/intel/utils/autopatch.py 544564
# Enable ACPI & VT-x/d
#vendor/intel/utils/autopatch.py 550913
# Tipc-test result check
vendor/intel/utils/autopatch.py 523435

./device/intel/mixins/mixin-update

source build/envsetup.sh
lunch bxtp_abl-userdebug

#apply_patch bionic            a/aosp/platform/bionic            refs/changes/89/510889/4 
#apply_patch bootable/recovery a/aosp/platform/bootable/recovery refs/changes/05/510905/4
#apply_patch system/core       a/aosp/platform/system/core       refs/changes/06/510906/3
#apply_patch system/sepolicy   a/aosp/platform/system/sepolicy   refs/changes/07/510907/3
#apply_patch bionic            a/aosp/platform/bionic            refs/changes/12/510912/4
#apply_patch build             a/aosp/platform/build             refs/changes/05/514205/3
#apply_patch frameworks/base   a/aosp/platform/frameworks/base   refs/changes/66/516366/2
#apply_patch frameworks/base   a/aosp/platform/frameworks/base   refs/changes/76/522276/2
#apply_patch system/core       a/aosp/platform/system/core       refs/changes/13/510913/4
#apply_patch system/core       a/aosp/platform/system/core       refs/changes/58/518958/1
#apply_patch prebuilts/sdk     a/aosp/platform/prebuilts/sdk     refs/changes/57/518957/1


#make ABL_BUILD_FROM_SRC=true flashfiles -j8 2>&1 |tee build_bxtp_abl.log
#make flashfiles -j8 2>&1 |tee build_bxtp_abl.log
make flashfiles -j20 2>&1 |tee build_bxtp_abl.log

mmm system/core/trusty/libtrusty
mmm system/core/trusty/libtrusty/tipc-test

croot
#make ABL_BUILD_FROM_SRC=true flashfiles -j8 2>&1 |tee build_bxtp_abl_tipc.log
make flashfiles -j20 2>&1 |tee build_bxtp_abl_tipc.log
}

#build bxt-p for M                                                                                                                                                                                          
build_bxtp_abl_for_M(){

cd $build_dir

# Tipc-test result check
vendor/intel/utils/autopatch.py 523435

# Re-enable trusty
vendor/intel/utils/autopatch.py 554571 554572 554573

# Enable ipc-unittest
vendor/intel/utils/autopatch.py 555615
vendor/intel/utils/autopatch.py 549858

# Avoid accidentally using the host's native 'as' command.
vendor/intel/utils/autopatch.py 545613

./device/intel/mixins/mixin-update

source build/envsetup.sh
lunch r0_bxtp_abl-userdebug

make flashfiles -j20 2>&1 |tee build_bxtp_abl.log

mmm system/core/trusty/libtrusty
mmm system/core/trusty/libtrusty/tipc-test

croot
make flashfiles -j20 2>&1 |tee build_bxtp_abl_tipc.log
}

#send mail
send_mail() {
email_body=$build_dir/email.log

 echo "sending mail..."
  if [[ $(grep -o "make completed successfully" $build_dir/build_bxtp_abl_tipc.log) != "" ]] ; then
      email_subject="1A Trusty Daily Build Successful From Antec"
      echo "Today's 1A Trusty Daily Build Successful! From ANTEC " >> $email_body
      echo "Image can be found here @ http://10.239.92.141/IMAGES/$build_dir  " >> $email_body
      echo "Please refer to doc https://docs.google.com/document/d/1IpYgykgF2L9ML7olSv1BpFeUEWoBHOHboTYvnucRGNg/edit#heading=h.qb88tgkvuvcj for how to use the image" >>$email_body


  else
      email_subject="1A Trusty Daily Build FAIL From Antec"
      echo "Today's 1A Trusty Daily Build FAILED! From ANTEC" >> $email_body
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

#get_code android/master r0
#build_bxtp_abl

get_code integ/bxtp_ivi_m bxtp_ivi_m
build_bxtp_abl_for_M

#build_gsd

clean_old

send_mail

