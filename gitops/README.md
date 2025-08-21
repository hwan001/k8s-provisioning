# GitOps

- flux 경로는 self-managing 패턴으로 최초 한 번만 bootstrap/적용 해두면 이후부터는 flux 자신도 Git으로 통제됨
- ImageRepository 같은 flux의 CRDs는 flux/source경로에 위치
- apps는 자체 개발 서비스
- crds, policies 는 리소스
