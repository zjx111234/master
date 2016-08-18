#!/bin/bash
tt=0
#数据结构改变前变量获取
DB_info_old=$(mysql -uroot -proot -e "show databases;" | grep -v Database)
DB_info_old1=$(mysql -uroot -proot -e "show databases;" | grep -v Database)

#获取修改的数据库名Changed_DB
cd /data/wwwroot/DBfile
Folder_A="/data/wwwroot/DBfile"
        for file_a in ${Folder_A}/*; do
                temp_file=`basename $file_a`
                sed -i 's///g' $file_a
                Create_temp=$(sed -n '/CREATE DATABASE/p' $file_a)
                #是否创建数据库
                if [[ ! $Create_temp ]]
                        then
				#获得改变的表的表名			
				table=$(cat $file_a|grep "Source Table" )
				table=${table#*:}
				OLD_IFS="$IFS"
                                IFS=","
				table_arr=($table)
				IFS=”$OLD_IFS”
				for s in ${table_arr[@]}
					do
						Changed_table=(${Changed_table[*]} $s )				
					done
				
				#将修改的数据库名存入数组
				DB_Name=$(sed -n '/Source Database/p' $file_a | awk '{print $4}')
				Changed_DB=(${Changed_DB[*]} $DB_Name)
				
		fi
	done
#数据库名去重
len_db=${#Changed_DB[@]}
for((i=0;i<$len_db;i++))
	do
        	for((j=$len_db-1;j>i;j--))
                	do
                       		if [[ ${Changed_DB[i]} = ${Changed_DB[j]} ]]; then
                                	unset Changed_DB[j]
                                        	fi
                       done
        done



#表名去重
len_table=${#Changed_DB[@]}     
for((i=0;i<$len_table;i++))
	do
		for((j=$len_table-1;j>i;j--))
                	do
				if [[ ${Changed_DB[i]} = ${Changed_DB[j]} ]]; then
                                	unset Changed_DB[j]
                                fi

                        done
	done

#获得修改前数据库表状态
for arr in ${Changed_DB[@]};
		do
                	Table_Staute_old[$tt]=$(mysql -uroot -proot -e "use $arr;show tables;"| grep -v Tables_in_)
                	Table_Staute_old1[$tt]=$(mysql -uroot -proot -e "use $arr;show tables;"| grep -v Tables_in_)
                         tt=$((tt+1))
		done

#获得修改前表结构状态
qq=0
for arr in ${Changed_table[@]};
                do 
	
			Current_DB[$qq]=$(mysql -uroot -proot -e "use information_schema;SELECT TABLE_SCHEMA from TABLES WHERE TABLE_NAME = '$arr';" |grep -v mysql |grep -v TABLE_SCHEMA) &> /dev/null
			Table_desc_old[$qq]=$(mysql -uroot -proot -e "use ${Current_DB[$qq]};describe $arr;" -vvv) &>/dev/null
			qq=$((qq+1))
                done



#执行.sql文件
Folder_A="/data/wwwroot/DBfile"
        for file_a in ${Folder_A}/*; do
                temp_file=`basename $file_a`   
                Create_temp=$(sed -n '/CREATE DATABASE/p' $file_a)
		#是否创建数据库
		if [[ $Create_temp ]]
			then
				mysql -uroot -proot mysql < $temp_file
			else
				DB_Name=$(sed -n '/Source Database/p' $file_a | awk '{print $4}')
				#将修改的数据库名存入数组
			#	Table_name=($temp_file)
				mysql -uroot -proot $DB_Name < $temp_file 
				fi
	done


#修改完成后数据库表信息
ss=0
for arr in ${Changed_DB[@]};
	do
		Table_Staute_new[$ss]=$(mysql -uroot -proot -e "use $arr;show tables;"| grep -v Tables_in_)
                Table_Staute_new1[$ss]=$(mysql -uroot -proot -e "use $arr;show tables;"| grep -v Tables_in_)
               	ss=$((ss+1))
        done

cd /data

#数据库修改后信息
DB_info_new=$(mysql -uroot -proot -e "show databases;" | grep -v Database)
DB_info_new1=$(mysql -uroot -proot -e "show databases;" | grep -v Database)


#数据库表结构修改后信息
ff=0
for arr in ${Changed_table[@]};
                do

                        Current_DB[$ff]=$(mysql -uroot -proot -e "use information_schema;SELECT TABLE_SCHEMA from TABLES WHERE TABLE_NAME = '$arr';" |grep -v mysql |grep -v TABLE_SCHEMA) &> /dev/null
                        Table_desc_new[$ff]=$(mysql -uroot -proot -e "use ${Current_DB[$ff]};describe $arr;" -vvv) &>/dev/null
                        ff=$((ff+1))
                done




#变化输出
echo "####################"$(date +%Y%m%d-%H%M)Alter"#####################" >> DB_Alterlog-$(date +%Y%m%d-%H%M).txt
echo -e " \n ">>/data/DB_Alterlog-$(date +%Y%m%d-%H%M).txt



# 数据库变化判断
for s in $DB_info_old;
        do
                for t in $DB_info_new;
                        do
                                if [[ $s=$t ]]
                                        then
                                                DB_info_new=$(echo $DB_info_new | sed 's/'$s'//g ')

                                fi
			done
	done

	if [[ $DB_info_new ]]
			then
		echo "Add New DataBase $DB_info_new" >> DB_Alterlog-$(date +%Y%m%d-%H%M).txt
		echo -e " \n ">>/data/DB_Alterlog-$(date +%Y%m%d-%H%M).txt
	fi


for a in $DB_info_new1;
        do
                for b in $DB_info_old1;
                        do
                                if [[ $a=$b ]]
                                        then
                                                 DB_info_old1=$(echo $DB_info_old1 | sed 's/'$a'//g ')

                               fi
		        done
	done
	
	if [[ $DB_info_old1 ]];then
		echo "Del New DataBase $DB_info_old1" >> DB_Alterlog-$(date +%Y%m%d-%H%M).txt
		echo -e " \n ">>/data/DB_Alterlog-$(date +%Y%m%d-%H%M).txt
	fi


#数据库表变化判断
a=0
for ((c=0;c<tt;c++));do
	for s1 in ${Table_Staute_old[$c]};
        do
		len_s1=$(echo $s1|wc -L)
                for t2 in ${Table_Staute_new[$c]};
                                        do
                                                len_t2=$(echo $t2|wc -L)
                                                if [[ $len_s1 -ne $len_t2 ]]&&[[ $t2 =~ "$s1" ]];then
                                                        Table_Staute_new[$c]=$(echo ${Table_Staute_new[$c]} | sed 's/'$t2'//g ')
                                                        long_c[$a]=$t2
                                                        a=$((a+1))
                                                        fi
                                        done
		for t1 in ${Table_Staute_new[$c]};
                        do
		
				if [[ $s1 = $t1 ]];then
                                              Table_Staute_new[$c]=$(echo ${Table_Staute_new[$c]} | sed 's/'$s1'//g ')
                                fi
				
				for((i=0;i<a;i++));
					do
						zz=$(echo ${Table_Staute_new[$c]}|grep "${long_c[$i]}")	
						if [[ ! $zz =~ "${long_c[$i]}" ]]
							then
							Table_Staute_new[$c]=${Table_Staute_new[$c]}"${long_c[$i]}"
						fi
					done
				done
        done

 if [[ ${Table_Staute_new[$c]} ]];then
	
	echo Datebase:${Changed_DB[$c]} Add Table ${Table_Staute_new[$c]}>> DB_Alterlog-$(date +%Y%m%d-%H%M).txt
	echo -e " \n ">>/data/DB_Alterlog-$(date +%Y%m%d-%H%M).txt
fi
h=0
for a1 in ${Table_Staute_new1[$c]};
        do
                len_a1=$(echo $a1|wc -L)
			for b2 in ${Table_Staute_old1[$c]};
                                        do
                                                len_b2=$(echo $b2|wc -L)
                                                if [[ $len_a1 -ne $len_b2 ]]&&[[ $b2 =~ "$a1" ]];then
                                                        Table_Staute_old1[$c]=$(echo ${Table_Staute_old1[$c]} | sed 's/'$b2'//g ')
                                                        long_d[$h]=$b2
                                                        h=$((h+1))
                                                        fi
                                        done



			for b1 in ${Table_Staute_old1[$c]};
                        do
                                if [ $a1 = $b1 ];then
                                               Table_Staute_old1[$c]=$(echo ${Table_Staute_old1[$c]}| sed 's/'$a1'//g ')
						#echo ${Table_Staute_old1[$c]}
					fi
                        

				
				 for((i=0;i<h;i++));
                                        do
                                                zz=$(echo ${Table_Staute_old1[$c]}|grep "${long_d[$i]}")
                                                if [[ ! $zz =~ "${long_c[$i]}" ]]
                                                        then
                                                        Table_Staute_old1[$c]=${Table_Staute_old1[$c]}"${long_d[$i]}"
                                                fi
                                        done

				done
        done
	


if [[ ${Table_Staute_old1[$c]} ]];then	

	 echo Datebase:${Changed_DB[$c]} Del Table ${Table_Staute_old1[$c]} >> DB_Alterlog-$(date +%Y%m%d-%H%M).txt
	echo -e " \n ">>/data/DB_Alterlog-$(date +%Y%m%d-%H%M).txt
fi

done



#输出改变前表结构信息
for((i=0;i<qq;i++))
        do
                        echo Before Change DB:${Current_DB[$i]} Table:${Changed_table[$i]} >>/data/DB_Alterlog-$(date +%Y%m%d-%H%M).txt
                        echo ${Table_desc_old[$i]} >>/data/DB_Alterlog-$(date +%Y%m%d-%H%M).txt
                        echo -e " \n ">>/data/DB_Alterlog-$(date +%Y%m%d-%H%M).txt
        done

#输出改变后表结构信息

for((i=0;i<ff;i++))
        do
                        echo After  Change DB:${Current_DB[$i]} Table:${Changed_table[$i]} >>/data/DB_Alterlog-$(date +%Y%m%d-%H%M).txt
                        echo ${Table_desc_new[$i]} >>/data/DB_Alterlog-$(date +%Y%m%d-%H%M).txt
                        echo -e " \n ">>/data/DB_Alterlog-$(date +%Y%m%d-%H%M).txt
        done

#发送邮件


ReturnMes=$(cat /data/DB_Alterlog-$(date +%Y%m%d-%H%M).txt)
echo "$ReturnMes" | mail -s "ALterDatabase"  zhangjiaxu@yiche.com
