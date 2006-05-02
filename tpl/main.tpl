
##include_menu_main.inc##

<h1>DiCoP Proxy - Detailed Status</h1>

<div class="text">

<p>
 My name is <b>'##name##'</b> (type <b>##servertype##</b>) and I run DiCoP-Proxy
 <b>v##version##</b> build <b>##build##</b> under <b>##os##</b> as user
 <b>##user##</b>, group <b>##group##</b> (<b>##chroot##</b>) for now
 <b>##runningtime##</b>.
</p>

<p>
 I handled <b>##requests##</b> requests
  (<font size="-1"><b>##auth_requests##</b> auth, 
  <b>##status_requests##</b> status, 
  <b>##report_requests##</b> reports
  (<b>##report_work_requests##</b> work, <b>##report_test_requests##</b> test),
  <b>##request_requests##</b> requests
  (<b>##request_work_requests##</b> work, <b>##request_test_requests##</b> test)
  </font>)
 on <b>##connects##</b> client connects.
</p>

<p>
 It took <b>##all_connects_time##s</b> to handle all connects, <b>##last_connect_time##s</b>
 for the last connect, and the average time per connect
 is so far <b>##average_connect_time##s</b>.
</p>

</div>
