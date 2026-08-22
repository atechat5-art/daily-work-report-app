# Daily Flow — 일일 업무 보고 앱

직원의 일일 업무보고와 주요 프로젝트 현황을 모바일에서 관리하는 React/Vite 앱입니다.

## 실행

1. `.env.example`을 복사해 `.env`로 만들고 Supabase Project URL 및 anon key를 입력합니다.
2. Supabase SQL Editor에서 `supabase/schema.sql`을 실행합니다.
3. `npm install && npm run dev`

Supabase가 설정되지 않으면 화면을 검토할 수 있는 데모 모드로 실행됩니다. 실제 저장·로그인은 환경변수와 SQL 스키마 설정 후 동작합니다.

## 관리자 설정

회원가입 후 SQL Editor에서 해당 사용자를 관리자로 바꿉니다.

```sql
update public.profiles set role = 'admin' where id = '사용자 UUID';
```

## Vercel 배포

Vercel 프로젝트의 Environment Variables에 `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`를 Production/Preview 모두 등록한 뒤 배포합니다.
