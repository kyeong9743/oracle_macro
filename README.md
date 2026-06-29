---
<details>
<summary>(KR) 한국어</summary>

# 이 프로젝트는?

Oracle Cloud는 Always Free(상시 무료) 티어를 제공합니다. 
Oracle이 제공하는 Ampere A1 인스턴스는 전 세계적으로 경쟁이 치열하기에
해당 인스턴스를 자동으로 확보하기 위한 스크립트와,
인스턴스 정지 후 자원이 회수되는경우 다시 할당하는 2개의 스크립트를 담고있습니다.

---

## Oracle Cloud 무료 티어

| 항목   | OCI Free Tier A1   | OCI Free Tier Micro |
| ------ | ------------------ | ------------------- |
| CPU    | 2 OCPU (ARM)       | 1 OCPU (AMD)        |
| RAM    | 12 GB              | 1 GB                |
| 디스크 | 최대 200GB         | 최대 200GB          |
| 기간   | **영구 무료**      | **영구 무료**       |
| 개수   | 총량 내에서 쪼개기 가능 | VM 최대 2개      |

> ※ A1의 2 OCPU / 12 GB는 계정 전체에 할당되는 **총량**이며, 이 한도 내에서 여러 인스턴스로 나눠 사용할 수 있습니다.

> ※ 블록 볼륨은 계정당 200GB까지 무료로, 여러 인스턴스에 나눠서 사용 가능합니다.

> ※ 무료 티어 사양·정책은 Oracle 정책에 따라 변경될 수 있으니, 최신 사양은 [공식 문서](https://www.oracle.com/cloud/free/) 참고

> ※ 2026년 6월, Always Free 정책 변경으로 4 OCPU, 24 Memory -> 2 OCPU, 12 Memory 로 변경되었습니다.

---

## 인스턴스 생성 (oci-create.sh)

### 필요한 정보

| 항목                | 가져오는 곳 |
| ------------------- | ----------- |
| User OCID           | 웹 콘솔 우측 상단 [프로필 아이콘] → [사용자 설정(User Settings)] → `ocid1.user.oc1...` |
| Tenancy OCID        | 웹 콘솔 우측 상단 [프로필 아이콘] → [테넌시(Tenancy): 계정이름] → `ocid1.tenancy.oc1...` |
| Availability Domain | `ap-chuncheon-1` 또는 본인 리전 이름 |
| Subnet OCID         | OCI 콘솔 → Networking → VCN → Subnets → OCID 복사 |
| Image OCID          | OCI 콘솔 → Compute → Images → 원하는 이미지 OCID |
| SSH Key             | 하단 Step 3에서 생성 |

---

### Step 1: OCI CLI 설치

설치 스크립트를 실행합니다.

```bash
curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh | bash
```

설치 후 `oci setup config` 마법사가 묻는 항목을 순서대로 입력합니다. (이 단계를 건너뛰고 나중에 직접 config 파일을 작성해도 됩니다.)

1. **Enter a location for your config**: 그냥 엔터 (기본값 `~/.oci/config`)
2. **Enter a user OCID**: 웹 콘솔 [프로필] → [사용자 설정]에서 확인한 `ocid1.user.oc1...`
3. **Enter a tenancy OCID**: 웹 콘솔 [프로필] → [테넌시: 계정이름]에서 확인한 `ocid1.tenancy.oc1...`
4. **Enter a region**: `ap-chuncheon-1` 또는 본인 리전 이름(혹은 목록에서 번호 선택)
5. **Do you want to generate a new API Signing RSA key pair?**: `Y` 입력 (새 키 생성)
6. **Enter a directory for your keys** `[/home/계정이름/.oci]`: 그냥 엔터 (기본값)
7. **Enter a name for your key** `[oci_api_key]`: 그냥 엔터 (기본값)
8. **Enter a passphrase for your private key (press enter for no passphrase)**: 그냥 엔터 (passphrase 없음 — 매크로 자동 실행 시 편함)

설정이 끝나면 터미널에 공개 키가 저장된 경로(보통 `~/.oci/oci_api_key_public.pem`)가 출력됩니다. 해당 키의 내용을 출력합니다.

```bash
cat ~/.oci/oci_api_key_public.pem
```

화면에 나오는 `-----BEGIN PUBLIC KEY-----`부터 `-----END PUBLIC KEY-----`까지 전체 내용을 복사합니다.

이후 웹 콘솔에서 등록합니다.

1. 웹 콘솔 → [프로필] → [사용자 설정] → 왼쪽 아래 [API 키] 메뉴 클릭
2. [API 키 추가] → [공개 키 붙여넣기] 선택
3. 복사한 내용을 붙여넣고 추가

터미널이 `oci` 명령어를 인식하도록 환경 변수를 새로고침하고 설치를 확인합니다.

```bash
source ~/.bashrc
oci --version
```

---

### Step 2: 스크립트 설정

```bash
curl -o ./oci-create.sh https://raw.githubusercontent.com/kyeong9743/oracle-cloud-macro/main/script/oci-create.sh
chmod +x ./oci-create.sh
vi ./oci-create.sh
```

수정해야 할 변수들:

| 변수                  | 설명 |
| --------------------- | ---- |
| `COMPARTMENT_ID`      | 컴파트먼트 OCID (루트 컴파트먼트를 쓰는 경우 Tenancy OCID, 별도 컴파트먼트는 해당 OCID) |
| `AVAILABILITY_DOMAIN` | 가용성 도메인 / 예) `Rhgk:AP-CHUNCHEON-1-AD-1` (접두사는 테넌시마다 다름) |
| `SUBNET_ID`           | 서브넷 OCID / Subnet OCID |
| `IMAGE_ID`            | OS 이미지 OCID / Image OCID |
| `INSTANCE_NAME`       | 생성할 인스턴스 이름 / Instance Name |
| `VOLUME_SIZE`         | 볼륨 사이즈 / Volume size |
| `SSH_KEY_FILE`        | SSH 공개 키 파일 경로 / 예) `my_oracle_vm_key.pub` |

---

### Step 3: SSH 키 생성

로컬 PC에서 SSH 키 쌍(개인 키 + 공개 키)을 생성합니다.

```bash
ssh-keygen -t rsa -b 4096 -m PEM -f ./my_oracle_vm_key
```

- 비밀번호 입력창이 나오면 그냥 엔터
- 비밀번호를 설정하면 보안이 강화되지만, 키 사용 시마다 입력해야 하므로 자동화에는 권장하지 않습니다.

위 명령으로 개인 키 `my_oracle_vm_key`와 공개 키 `my_oracle_vm_key.pub`가 생성됩니다. Step 2의 `SSH_KEY_FILE`에는 공개 키(`.pub`) 경로를 지정합니다.

---

### Step 4: 스크립트 실행

```bash
# 포그라운드 실행
./oci-create.sh

# 백그라운드 실행
nohup ./oci-create.sh > /dev/null 2>&1 &

# 실시간 로그 확인
tail -f ./oci-instance-created.log
```

---

# 인스턴스 자원이 회수된 후 다시 할당할 때 (oci-start-auto.sh)

## 필요한 정보

| 항목           | 가져오는 곳          |
| -------------- | -------------------- |
| Instance OCID  | 인스턴스 → 세부정보 |

---

## Step 1: 스크립트 설정

```bash
curl -o ./oci-start-auto.sh https://raw.githubusercontent.com/kyeong9743/oracle-cloud-macro/main/script/oci-start-auto.sh
chmod +x ./oci-start-auto.sh
vi ./oci-start-auto.sh
```

수정해야 할 변수들:

| 변수          | 설명 |
| ------------- | ---- |
| `INSTANCE_ID` | 인스턴스 OCID / Instance OCID |

---

## Step 2: 스크립트 실행

```bash
# 포그라운드 실행
./oci-start-auto.sh

# 백그라운드 실행
nohup ./oci-start-auto.sh > /dev/null 2>&1 &

# 실시간 로그 확인
tail -f ./oci-start.log
```

---

## 참고

- [OCI Free Tier 공식 문서](https://www.oracle.com/cloud/free/)
- [nahyeongjin1/oci-instance-creator](https://github.com/nahyeongjin1/oci-instance-creator/blob/main/README.md)


</details>

<details>
<summary>(EN) English</summary>

# About This Project?

Oracle Cloud offers an Always Free tier. Due to intense global competition for Oracle's Ampere A1 instances, this includes two scripts: one to automatically secure the instance, and another to reallocate resources if they are reclaimed after the instance stops.

---

## Oracle Cloud Free Tier

| Item     | OCI Free Tier A1        | OCI Free Tier Micro |
| -------- | ----------------------- | ------------------- |
| CPU      | 2 OCPU (ARM)            | 1 OCPU (AMD)        |
| RAM      | 12 GB                   | 1 GB                |
| Disk     | Up to 200GB             | Up to 200GB         |
| Duration | **Always Free**         | **Always Free**     |
| Count    | Splittable within total | Up to 2 VMs         |

> ※ The A1's 2 OCPU / 12 GB is the **total** allocated per account; you can split it across multiple instances within this limit.

> ※ Block volume is free up to 200GB per account and can be split across instances.

> ※ Free tier specs and policies are subject to change by Oracle. Check the [official docs](https://www.oracle.com/cloud/free/) for current specs.

> ※ In June 2026, the Always Free policy was updated, changing the resources from 4 OCPU, 24 Memory to 2 OCPU, 12 Memory.
> 
---

## Creating an Instance (oci-create.sh)

### Required Information

| Item                | Where to Get It |
| ------------------- | --------------- |
| User OCID           | Web console top-right [Profile] → [User Settings] → `ocid1.user.oc1...` |
| Tenancy OCID        | Web console top-right [Profile] → [Tenancy: account name] → `ocid1.tenancy.oc1...` |
| Availability Domain | `ap-chuncheon-1` or your region name |
| Subnet OCID         | OCI Console → Networking → VCN → Subnets → copy OCID |
| Image OCID          | OCI Console → Compute → Images → desired image OCID |
| SSH Key             | Generated in Step 3 below |

---

### Step 1: Install OCI CLI

Run the install script.

```bash
curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh | bash
```

After installation, the `oci setup config` wizard will prompt for the following in order. (You may skip this and write the config file manually later.)

1. **Enter a location for your config**: Press Enter (default `~/.oci/config`)
2. **Enter a user OCID**: The `ocid1.user.oc1...` from [Profile] → [User Settings]
3. **Enter a tenancy OCID**: The `ocid1.tenancy.oc1...` from [Profile] → [Tenancy: account name]
4. **Enter a region**: `ap-chuncheon-1` or your region name (or select by number from the list)
5. **Do you want to generate a new API Signing RSA key pair?**: Enter `Y` (generate a new key)
6. **Enter a directory for your keys** `[/home/username/.oci]`: Press Enter (default)
7. **Enter a name for your key** `[oci_api_key]`: Press Enter (default)
8. **Enter a passphrase for your private key (press enter for no passphrase)**: Press Enter (no passphrase — easier for automated/macro runs)

Once setup is complete, the terminal prints the path to your public key (usually `~/.oci/oci_api_key_public.pem`). Print its contents.

```bash
cat ~/.oci/oci_api_key_public.pem
```

Copy the entire content from `-----BEGIN PUBLIC KEY-----` to `-----END PUBLIC KEY-----`.

Then register it in the web console.

1. Web console → [Profile] → [User Settings] → [API Keys] menu (bottom left)
2. [Add API Key] → select [Paste Public Key]
3. Paste the copied content and add it

Refresh environment variables so the terminal recognizes the `oci` command, then verify the installation.

```bash
source ~/.bashrc
oci --version
```

---

### Step 2: Configure the Script

```bash
curl -o ./oci-create.sh https://raw.githubusercontent.com/kyeong9743/oracle-cloud-macro/main/script/oci-create.sh
chmod +x ./oci-create.sh
vi ./oci-create.sh
```

Variables to edit:

| Variable              | Description |
| --------------------- | ----------- |
| `COMPARTMENT_ID`      | Compartment OCID (Tenancy OCID if using the root compartment; otherwise the specific compartment OCID) |
| `AVAILABILITY_DOMAIN` | Availability domain / e.g. `Rhgk:AP-CHUNCHEON-1-AD-1` (the prefix differs per tenancy) |
| `SUBNET_ID`           | Subnet OCID |
| `IMAGE_ID`            | OS Image OCID |
| `INSTANCE_NAME`       | Name of the instance to create |
| `VOLUME_SIZE`         | Volume size |
| `SSH_KEY_FILE`        | Path to the SSH public key file / e.g. `my_oracle_vm_key.pub` |

---

### Step 3: Generate an SSH Key

On your local PC, generate an SSH key pair (private key + public key).

```bash
ssh-keygen -t rsa -b 4096 -m PEM -f ./my_oracle_vm_key
```

- When prompted for a passphrase, just press Enter.
- A passphrase improves security but must be entered each time the key is used, so it is not recommended for automation.

This creates the private key `my_oracle_vm_key` and the public key `my_oracle_vm_key.pub`. Set `SSH_KEY_FILE` in Step 2 to the public key (`.pub`) path.

---

### Step 4: Run the Script

```bash
# Foreground
./oci-create.sh

# Background
nohup ./oci-create.sh > /dev/null 2>&1 &

# Watch logs in real time
tail -f ./oci-instance-created.log
```

---

# Re-Allocating After Resources Are Reclaimed (oci-start-auto.sh)

## Required Information

| Item          | Where to Get It    |
| ------------- | ------------------ |
| Instance OCID | Instance → Details |

---

## Step 1: Configure the Script

```bash
curl -o ./oci-start-auto.sh https://raw.githubusercontent.com/kyeong9743/oracle-cloud-macro/main/script/oci-start-auto.sh
chmod +x ./oci-start-auto.sh
vi ./oci-start-auto.sh
```

Variables to edit:

| Variable      | Description   |
| ------------- | ------------- |
| `INSTANCE_ID` | Instance OCID |

---

## Step 2: Run the Script

```bash
# Foreground
./oci-start-auto.sh

# Background
nohup ./oci-start-auto.sh > /dev/null 2>&1 &

# Watch logs in real time
tail -f ./oci-start.log
```

---

## References

- [OCI Free Tier Official Docs](https://www.oracle.com/cloud/free/)
- [nahyeongjin1/oci-instance-creator](https://github.com/nahyeongjin1/oci-instance-creator/blob/main/README.md)

</details>

<details>
<summary>Gitbook</summary>
본 GitBook 문서는 인스턴스를 자동으로 확보하기 위한 스크립트를 제작해 인스턴스를 확보하고, SSH 키를 분실했을 때 배스천(Bastion)을 이용해 새 키를 주입하며, 인스턴스 정지 후 자원이 회수되어 다시 할당하기까지의 과정을 담았습니다.

This GitBook documentation covers the entire process: securing an instance with an automated script, injecting a new SSH key via Bastion if the original is lost, and reallocating resources after an instance is stopped and reclaimed.

[![한국어 문서](https://img.shields.io/badge/GitBook-한국어_문서-3185FF?style=for-the-badge&logo=gitbook&logoColor=white)](https://kyeong9743.gitbook.io/oracle-cloud/ko)
[![English Docs](https://img.shields.io/badge/GitBook-English_Docs-3185FF?style=for-the-badge&logo=gitbook&logoColor=white)](https://kyeong9743.gitbook.io/oracle-cloud/en-english)
</details>



