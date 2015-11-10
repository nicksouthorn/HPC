#!/usr/bin/perl
sub Toggle_MSR{   # short term fix for turbo bug in bios
   my $DEBUG=0;
   my $CPU_State_Requested =$_[0];
   my $CMD_LINE;
   my $TurboEnabled=0;
   my $RETURN;
   my $ncores = qx(cat /sys/devices/system/cpu/cpu*/topology/thread_siblings | wc -l);
   my $FlipTheBit = 0;
   my $host=qx(hostname);
   my $tmp_a="0x" . qx(/lustre/home/sgi/sgi/abaqus/cases/noturbo/rdmsr -p 0 0x199);
   my $Freq_turbo="2601000";
   my $Freq_noTurbo="2600000";
   chomp ($host);
   my $MSRTurboFixComment="BIOS fix: ";

$t1 = time() if $DEBUG;

   chomp $tmp_a;

   $TurboEnabled=1 if ( length($tmp_a) < 8  );  # hex > 8 noturbo

   print "$MSRTurboFixComment Current State: Turbo, Requested: $CPU_State_Requested ...  Enabled\n" if ($TurboEnabled == 1);
   print "$MSRTurboFixComment Current State: NoTurbo, Requested: $CPU_State_Requested ...  Enabled\n" if ($TurboEnabled != 1);

   
   if ( $CPU_State_Requested eq "Turbo" && $TurboEnabled != 1 ) {
      print "enable turbo, run wrmsr \n" if $DEBUG;
      qx(cpupower frequency-set -d ${Freq_turbo} -u ${Freq_turbo} -g performance);
      $FlipTheBit = 1;
   }
   elsif ($CPU_State_Requested eq "Turbo" && $TurboEnabled == 1 ) {
      qx(cpupower frequency-set -d ${Freq_turbo} -u ${Freq_turbo} -g performance);
      $FlipTheBit = 0;
   }
   elsif ($CPU_State_Requested eq "NoTurbo" && $TurboEnabled != 0 ) {
      print "Noturbo mode, run wrmsr \n" if $DEBUG;
      qx(cpupower frequency-set -d ${Freq_noTurbo} -u ${Freq_noTurbo} -g performance);
      $FlipTheBit = 1;
   }
   elsif ($CPU_State_Requested eq "NoTurbo" && $TurboEnabled == 0 ) {
      print "Noturbo mode already disabled\n" if $DEBUG;
      qx(cpupower frequency-set -d ${Freq_noTurbo} -u ${Freq_noTurbo} -g performance);
      $FlipTheBit = 0;
   }

   if ( $FlipTheBit == 1 ) {
      my $tmp_b=qx(perl -e "printf('%#x', $tmp_a ^ 0x100000000)");
      for (my $coreid=0; $coreid < $ncores; $coreid++) {
        qx(/lustre/home/sgi/sgi/abaqus/cases/noturbo/wrmsr -p $coreid 0x199 $tmp_b);
        print "Current Read MSR: $tmp_a\tWrite New MSR: $tmp_b\n" if $DEBUG;
      }
   }
$t2 = time() if $DEBUG;
printf("$host:  Toggle_MSR        execution time = %s seconds.\n", ($t2 - $t1)) if $DEBUG;
}

Toggle_MSR("NoTurbo");
#Toggle_MSR("Turbo");

