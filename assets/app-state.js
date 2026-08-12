(function(){
  const KEYS={students:'bm_demo_students',selectedStudent:'bm_selected_student',upload:'bm_demo_upload',review:'bm_demo_review',reviewConfirmed:'bm_demo_review_confirmed'};
  const fallbackStudents=[
    {name:'Jayden',form:'Tingkatan 2',cls:'2A',mastery:68,status:'attention',weak:'Rumusan · Main Idea',trend:'↓ 6%',evidence:18},
    {name:'Alyssa',form:'Tingkatan 4',cls:'4C',mastery:81,status:'improving',weak:'Claim → Evidence Link',trend:'↑ 12%',evidence:27},
    {name:'Bryan',form:'Tingkatan 1',cls:'1B',mastery:76,status:'stable',weak:'Kata Ganda',trend:'→ 1%',evidence:14},
    {name:'Sofia',form:'Tingkatan 5',cls:'5A',mastery:73,status:'improving',weak:'Inferens',trend:'↑ 8%',evidence:32},
    {name:'Daniel',form:'Tingkatan 3',cls:'3D',mastery:61,status:'attention',weak:'Huraian',trend:'↓ 4%',evidence:21},
    {name:'Mei Xin',form:'Tingkatan 2',cls:'2B',mastery:87,status:'stable',weak:'Tanda Baca',trend:'↑ 2%',evidence:25}
  ];
  function read(key,fallback){try{const v=localStorage.getItem(key);return v?JSON.parse(v):fallback}catch(e){return fallback}}
  function write(key,value){localStorage.setItem(key,JSON.stringify(value));return value}
  function getStudents(){return read(KEYS.students,fallbackStudents)}
  function saveStudents(v){return write(KEYS.students,v)}
  function getStudentByName(name){return getStudents().find(s=>s.name===name)||null}
  function selectStudent(name){localStorage.setItem(KEYS.selectedStudent,name);return getStudentByName(name)}
  function getSelectedStudent(){const p=new URLSearchParams(location.search).get('student');if(p){selectStudent(p);return getStudentByName(p)}const name=localStorage.getItem(KEYS.selectedStudent);return name?getStudentByName(name):getStudents()[0]||null}
  function saveUpload(payload){write(KEYS.upload,{...payload,createdAt:new Date().toISOString()});if(payload.studentName)selectStudent(payload.studentName)}
  function getUpload(){return read(KEYS.upload,null)}
  function saveReview(payload){write(KEYS.review,{...payload,updatedAt:new Date().toISOString()})}
  function getReview(){return read(KEYS.review,null)}
  function confirmReview(){localStorage.setItem(KEYS.reviewConfirmed,'1')}
  function isReviewConfirmed(){return localStorage.getItem(KEYS.reviewConfirmed)==='1'}
  function resetReviewConfirmation(){localStorage.removeItem(KEYS.reviewConfirmed)}
  window.BMState={KEYS,getStudents,saveStudents,getStudentByName,selectStudent,getSelectedStudent,saveUpload,getUpload,saveReview,getReview,confirmReview,isReviewConfirmed,resetReviewConfirmation};
})();