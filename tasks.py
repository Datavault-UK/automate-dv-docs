from distutils import dir_util
from pathlib import Path

from invoke import task, Context
import os


def reset_and_copy(src_dir, tgt_dir):
    # if Path(tgt_dir).exists():
    #     dir_util.remove_tree(tgt_dir)

    dir_util.copy_tree(src_dir, tgt_dir)


def trim_sql_files_in_path(tgt_dir: Path):
    for path in Path(tgt_dir).rglob('*.sql'):
        with open(path, "r") as f:
            lines = f.readlines()

        delete_linebreak = True

        with open(path, 'w') as f:
            for line in lines:
                if "-- Generated by AutomateDV (formerly known as dbtvault)" not in line and not line.isspace():
                    f.write(line)
                elif delete_linebreak and line.isspace():
                    pass
                elif "-- Generated by AutomateDV (formerly known as dbtvault)" in line:
                    pass
                else:
                    f.write(line)
                    delete_linebreak = False


@task
def run_dbt(c, target='snowflake', dbt_command='build'):
    with c.cd('./docs_snippets'):
        c.run('dbt clean')

        # Without ghosts

        command_1 = f'dbt {dbt_command} --exclude tag:ghost --target={target} --full-refresh'
        command_2 = f'dbt {dbt_command} --exclude tag:ghost --target={target}'

        print("Running command: ", command_1)
        c.run(command_1)

        print("Running command: ", command_2)
        c.run(command_2)

        # With ghosts

        command_3 = f"dbt {dbt_command} -s +tag:ghost --target={target} --full-refresh " \
                    f"--vars 'enable_ghost_records: true'"
        command_4 = f"dbt {dbt_command} -s +tag:ghost --target={target} " \
                    f"--vars 'enable_ghost_records: true'"

        print("Running command: ", command_3)
        c.run(command_3)

        print("Running command: ", command_4)
        c.run(command_4)


@task
def generate_models(c):
    with c.cd('./docs_snippets'):
        c.run('automate-dv generate models')


@task(iterable=['env_var'])
@task
def make_samples(c, platform=None, dbt_command="build"):
    targets = [
        'snowflake',
        'bigquery',
        'sqlserver',
        'postgres',
        'databricks'
    ]

    if platform in targets and platform:
        targets = [platform]

    reset_and_copy('./docs_snippets/models/',
                   f'./docs/assets/snippets/models/')

    generate_models(c)

    for target in targets:
        print(f"Running dbt ({dbt_command}) with {target}...")

        run_dbt(c, target=target, dbt_command=dbt_command)

        tgt_compiled = f'./docs/assets/snippets/compiled/{target}'

        print(f"Copy files to snippets directory for '{target}' ...")

        reset_and_copy('./docs_snippets/target/compiled/docs_snippets/models/',
                       tgt_compiled)

        trim_sql_files_in_path(tgt_compiled)


if __name__ == '__main__':
    make_samples(Context())
