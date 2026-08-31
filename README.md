# Домашнее задание к занятию "`Безопасность в облачных провайдерах`" - `Ефимов Вячеслав`

### Задание 1

#### [main.tf](https://github.com/IthnHuitn/clopro/blob/clopro3/main.tf)    [variables.tf](https://github.com/IthnHuitn/clopro/blob/clopro3/variables.tf)    [outputs.tf](https://github.com/IthnHuitn/clopro/blob/clopro3/outputs.tf)    [personal.auto.tfvars](https://github.com/IthnHuitn/clopro/blob/clopro3/personal.auto.tfvars)   

#### Обновлённый блок
```hcl
# ==================== KMS Resources ====================

# Создание ключа в KMS
resource "yandex_kms_symmetric_key" "bucket_key" {
  name              = "bucket-encryption-key"
  description       = "Key for bucket encryption"
  default_algorithm = "AES_256"
  rotation_period   = "8760h"
}

# Привязка ключа к сервисному аккаунту
resource "yandex_kms_symmetric_key_iam_binding" "key_binding" {
  symmetric_key_id = yandex_kms_symmetric_key.bucket_key.id
  role            = "kms.keys.encrypterDecrypter"
  members         = ["serviceAccount:${yandex_iam_service_account.storage_sa.id}"]
}

# ==================== Object Storage Resources ====================

# Включение шифрования для существующего бакета через null_resource
resource "null_resource" "enable_bucket_encryption" {
  provisioner "local-exec" {
    command = <<-EOT
      export AWS_ACCESS_KEY_ID="${yandex_iam_service_account_static_access_key.storage_key.access_key}"
      export AWS_SECRET_ACCESS_KEY="${yandex_iam_service_account_static_access_key.storage_key.secret_key}"
      export AWS_ENDPOINT_URL="https://storage.yandexcloud.net"
      
      aws s3api put-bucket-encryption \
        --bucket ${var.bucket_name} \
        --server-side-encryption-configuration "{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"aws:kms\",\"KMSMasterKeyID\":\"${yandex_kms_symmetric_key.bucket_key.id}\"}}]}" \
        --endpoint-url $AWS_ENDPOINT_URL
    EOT
  }

  depends_on = [
    yandex_kms_symmetric_key.bucket_key,
    yandex_kms_symmetric_key_iam_binding.key_binding,
    yandex_iam_service_account_static_access_key.storage_key
  ]
}

# Загрузка файла в существующий бакет
resource "yandex_storage_object" "image_object" {
  bucket       = var.bucket_name
  key          = var.image_object_key
  source       = var.image_file_path
  access_key   = yandex_iam_service_account_static_access_key.storage_key.access_key
  secret_key   = yandex_iam_service_account_static_access_key.storage_key.secret_key
  acl          = "public-read"
  content_type = "image/jpeg"

  depends_on = [null_resource.enable_bucket_encryption]
}
```


#### Зашифрованный файл
![clopro1-1](https://github.com/IthnHuitn/clopro/blob/clopro3/scr/clopro1-1.png)
#### Отсутствие доступа
![clopro1-2](https://github.com/IthnHuitn/clopro/blob/clopro3/scr/clopro1-2.png)


---
