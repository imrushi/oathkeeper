FROM golang:1.9-alpine

ARG git_tag
ARG git_commit

RUN apk add --no-cache git build-base curl
RUN curl -L -s https://github.com/golang/dep/releases/download/v0.3.2/dep-linux-amd64 -o $GOPATH/bin/dep
RUN chmod +x $GOPATH/bin/dep

WORKDIR /go/src/github.com/ory/oathkeeper

ADD ./Gopkg.lock ./Gopkg.lock
ADD ./Gopkg.toml ./Gopkg.toml
RUN dep ensure -vendor-only

ADD . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-s -X github.com/ory/oathkeeper/cmd.Version=$git_tag -X github.com/ory/oathkeeper/cmd.BuildTime=`TZ=UTC date -u '+%Y-%m-%dT%H:%M:%SZ'` -X github.com/ory/oathkeeper/cmd.GitHash=$git_commit" -a -installsuffix cgo -o oathkeeper

FROM scratch

COPY --from=0 /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=0 /go/src/github.com/ory/oathkeeper/oathkeeper /usr/bin/oathkeeper

ENTRYPOINT ["oathkeeper"]
